package com.example.ku_task_management

import android.app.ActivityOptions
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.net.Uri
import android.os.Build
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

    // 최초 실행 위젯 정보를 Dart에 전달한다. singleTask 재호출은 기존 폼을 유지한다.
    override fun getDartEntrypointArgs(): List<String> = listOf(
        intent.getStringExtra(WidgetActions.EXTRA_SOURCE) ?: "unknown",
        intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID).toString(),
    )

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
        /** singleTask와 SINGLE_TOP으로 연속 클릭 시 입력 중인 팝업을 재사용한다. */
        fun createIntent(context: Context, source: String, widgetId: Int) =
            Intent(context, WidgetTaskCreateActivity::class.java).apply {
                data = Uri.parse("kutodo://widget/$source/$widgetId/create")
                putExtra(WidgetActions.EXTRA_SOURCE, source)
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            }

        fun pendingIntent(context: Context, source: String, widgetId: Int): PendingIntent {
            // 위젯별 URI로 PendingIntent를 구분해 다른 인스턴스의 source 덮어쓰기를 막는다.
            val intent = createIntent(context, source, widgetId)
            val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                val options = ActivityOptions.makeBasic()
                if (Build.VERSION.SDK_INT >= 35) {
                    options.setPendingIntentCreatorBackgroundActivityStartMode(
                        ActivityOptions.MODE_BACKGROUND_ACTIVITY_START_ALLOWED,
                    )
                } else {
                    options.pendingIntentBackgroundActivityStartMode =
                        ActivityOptions.MODE_BACKGROUND_ACTIVITY_START_ALLOWED
                }
                return PendingIntent.getActivity(context, 0, intent, flags, options.toBundle())
            }
            return PendingIntent.getActivity(context, 0, intent, flags)
        }
    }
}
