package com.example.acolle1

private val trunkNumber = Regex("""(?:55)?0([1-9]\d{9,10})""")
private val nationalNumber = Regex("""[1-9]\d{9,10}""")

internal fun normalizeCallerNumber(number: String): String {
    val digits = number.filter { it in '0'..'9' }
    val international = number.trimStart().startsWith("+") || digits.startsWith("00")
    val phone = digits.removePrefix("00")
    val trunk = trunkNumber.matchEntire(phone)
    if (trunk != null) return "55${trunk.groupValues[1]}"
    return if (!international && nationalNumber.matches(phone)) "55$phone" else phone
}
