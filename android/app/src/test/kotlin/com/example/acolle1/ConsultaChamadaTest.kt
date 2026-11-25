package com.example.acolle1

import android.content.Context
import android.content.Intent
import android.view.View
import java.net.InetAddress
import java.net.ServerSocket
import java.net.SocketException
import java.util.concurrent.ConcurrentLinkedQueue
import kotlin.concurrent.thread
import org.json.JSONObject
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28], manifest = Config.NONE)
class ConsultaChamadaTest {
    private val numeros = ConcurrentLinkedQueue<String>()
    private val respostas = ConcurrentLinkedQueue<Pair<Int, String>>()
    private val esperas = mutableListOf<Long>()
    private val numero = "+1 202 555 0100"
    private val semDenuncias = 200 to """{"suspeito":false,"reportes":0}"""
    private val context: Context get() = RuntimeEnvironment.getApplication()
    private lateinit var servidor: ServerSocket
    private lateinit var atendimento: Thread
    private lateinit var consulta: ConsultaReputacao

    @Before fun abrirServidor() {
        servidor = ServerSocket(0, 10, InetAddress.getByName("127.0.0.1"))
        atendimento = thread(isDaemon = true) {
            while (!servidor.isClosed) {
                val pedido = try { servidor.accept() } catch (e: SocketException) {
                    if (servidor.isClosed) break else throw e
                }
                pedido.use { socket ->
                    val entrada = socket.getInputStream().bufferedReader(Charsets.US_ASCII)
                    val cabecalhos = generateSequence { entrada.readLine() }.takeWhile { it.isNotEmpty() }.toList()
                    val tamanho = cabecalhos.first { it.startsWith("Content-Length:", ignoreCase = true) }
                        .substringAfter(':').trim().toInt()
                    val json = buildString { repeat(tamanho) { append(entrada.read().toChar()) } }
                    numeros.add(JSONObject(json).getString("numero"))
                    val (codigo, corpo) = respostas.poll() ?: (400 to "{}")
                    val bytes = corpo.toByteArray()
                    val saida = socket.getOutputStream()
                    saida.write("HTTP/1.1 $codigo Test\r\nContent-Length: ${bytes.size}\r\nConnection: close\r\n\r\n".toByteArray())
                    saida.write(bytes)
                }
            }
        }
        consulta = ConsultaReputacao("http://127.0.0.1:${servidor.localPort}/verificar") { esperas.add(it) }
    }

    @After fun fecharServidor() {
        servidor.close()
        atendimento.join(2000)
    }

    private fun verificar() = PhoneReputation.avaliarNumero(context, numero, consulta)

    @Test fun preservaCodigoDoPaisEReutilizaRespostaSemDenuncias() {
        respostas.add(semDenuncias)
        assertEquals(CallAlertStatus.CLEAR, verificar())
        assertEquals(CallAlertStatus.CLEAR, verificar())
        assertEquals(listOf("+12025550100"), numeros.toList())
    }

    @Test fun repeteUmaConsultaTemporariamenteLimitada() {
        respostas.add(429 to """{"error":"Tente novamente em instantes"}""")
        respostas.add(semDenuncias)
        assertEquals(CallAlertStatus.CLEAR, verificar())
        assertEquals(listOf(10_000L), esperas)
    }

    @Test fun falhaDeRedeNaoViraResultadoNemImpedeNovaConsulta() {
        repeat(2) { respostas.add(503 to "{}") }
        assertEquals(CallAlertStatus.UNAVAILABLE, verificar())
        respostas.add(200 to """{"suspeito":true,"reportes":2}""")
        assertEquals(CallAlertStatus.SUSPECT, verificar())
        assertEquals(3, numeros.size)
    }

    @Test fun resultadoParcialExigeListaConfirmadaRecente() {
        val prefs = context.getSharedPreferences(CALLER_ID_PREFS, Context.MODE_PRIVATE)
        prefs.edit().putLong(LISTA_CONFIRMADA_EM, System.currentTimeMillis() - 90_000_000L).commit()
        assertEquals(CallAlertStatus.UNAVAILABLE, verificar())
        prefs.edit().putLong(LISTA_CONFIRMADA_EM, System.currentTimeMillis()).commit()
        assertEquals(CallAlertStatus.LOCAL_ONLY, verificar())
        prefs.edit().putStringSet(SUSPECT_NUMBERS_KEY, setOf("12025550100")).commit()
        assertEquals(CallAlertStatus.SUSPECT, verificar())
        assertEquals(2, numeros.size)
    }

    @Test fun numeroIncompletoNaoAcionaServicoExterno() {
        assertEquals(CallAlertStatus.INCOMPLETE, PhoneReputation.avaliarNumero(context, "1234", consulta))
        assertEquals(0, numeros.size)
    }

    @Test fun resultadoSemDenunciasApareceNaTelaDeDetalhes() {
        respostas.add(semDenuncias)
        val intent = Intent(context, IncomingCallAlertActivity::class.java).apply {
            putExtra(IncomingCallAlertActivity.EXTRA_NUMBER, numero)
            putExtra(IncomingCallAlertActivity.EXTRA_STATUS, verificar().name)
        }
        val tela = Robolectric.buildActivity(IncomingCallAlertActivity::class.java, intent).setup()
        try {
            val encontrados = ArrayList<View>()
            tela.get().window.decorView.findViewsWithText(encontrados, "Nenhuma denúncia encontrada", View.FIND_VIEWS_WITH_TEXT)
            assertEquals(1, encontrados.size)
        } finally {
            tela.pause().stop().destroy()
        }
    }
}
