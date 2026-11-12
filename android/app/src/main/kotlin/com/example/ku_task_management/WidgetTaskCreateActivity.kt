package com.example.ku_task_management

import android.content.Context
import android.content.Intent
import es.antonborri.home_widget.HomeWidgetPlugin
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterActivityLaunchConfigs.BackgroundMode
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/** 메인 Activity를 열지 않고 두 위젯의 공통 등록 팝업을 실행한다. */
class WidgetTaskCreateActivity : FlutterActivity() {
    override fun getDartEntrypointFunctionName() = "widgetQuickCreate"

    // 홈 화면이 팝업 뒤로 보이도록 Flutter 배경을 투명하게 렌더링한다.
    override fun getBackgroundMode() = BackgroundMode.transparent

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "ku_todo/widget_quick_create")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    // Flutter 저장 완료 신호: 메인 앱 복귀 시 목록을 다시 조회하게 한다.
                    "saved" -> {
                        HomeWidgetPlugin.getData(this).edit()
                            .putBoolean(WidgetTaskCompleter.WIDGET_REFRESH_REQUIRED, true).commit()
                        result.success(null)
                    }
                    // 취소 또는 저장 완료 시 이 Activity만 닫고 이전 화면으로 돌아간다.
                    "close" -> {
                        result.success(null)
                        finish()
                    }
                    else -> result.notImplemented()
                }
            }
    }

    companion object {
        /** 두 위젯의 + 버튼에서 공통으로 사용할 명시적 실행 Intent. */
        fun createIntent(context: Context) = Intent(context, WidgetTaskCreateActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
    }
}
