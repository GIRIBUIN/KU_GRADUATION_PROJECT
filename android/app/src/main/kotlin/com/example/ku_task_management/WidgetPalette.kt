package com.example.ku_task_management

import android.graphics.Color

data class WidgetPalette(
    val surface: Int, val text: Int, val muted: Int, val input: Int, val button: Int,
    val accent: Int, val primary: Int, val outside: Int, val red: Int, val dark: Boolean,
) {
    fun surfaceWithOpacity(percent: Int) = (surface and 0x00ffffff) or ((percent.coerceIn(20, 100) * 255 / 100) shl 24)

    companion object {
        fun from(options: WidgetOptions): WidgetPalette {
            val theme = if (options.dark && options.theme == "light") "dark" else options.theme
            fun color(value: String) = Color.parseColor(value)
            return when (theme) {
                "dark" -> WidgetPalette(color("#1C2535"), color("#F1F5F9"), color("#B8C2D1"),
                    color("#273349"), color("#2D3D56"), color("#93C5FD"), color("#2B64BD"), color("#7F90A8"), color("#FDA4AF"), true)
                "gray" -> WidgetPalette(color("#E7E9EE"), color("#222C3C"), color("#586579"),
                    color("#F3F4F6"), color("#D9DFE8"), color("#275C9E"), color("#345E96"), color("#8793A4"), color("#B94053"), false)
                else -> WidgetPalette(Color.WHITE, color("#172033"), color("#667085"), color("#F3F6FB"),
                    color("#EDF3FC"), color("#1262D6"), color("#1262D6"), color("#9CA3AF"), color("#D95D69"), false)
            }
        }
    }
}
