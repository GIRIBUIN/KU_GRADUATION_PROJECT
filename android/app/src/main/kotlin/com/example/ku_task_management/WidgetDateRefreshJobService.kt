package com.example.ku_task_management

import android.app.job.JobParameters
import android.app.job.JobService
import android.os.Handler
import android.os.Looper
import android.util.Log
import es.antonborri.home_widget.HomeWidgetPlugin
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

/** Activity 없이 Flutter를 실행한다. 실패/OS 중단은 JobScheduler가 재시도한다. */
class WidgetDateRefreshJobService : JobService() {
    private val handler = Handler(Looper.getMainLooper())
    private var engine: FlutterEngine? = null
    private var channel: MethodChannel? = null
    private var active: JobParameters? = null
    private var timeout: Runnable? = null

    override fun onStartJob(params: JobParameters): Boolean {
        if (!WidgetDateRefresh.hasWidgets(this)) return false
        active = params
        val startedDate = WidgetDateRefresh.dateKey()
        timeout = Runnable { finishJob(params, false, startedDate) }.also { handler.postDelayed(it, 60_000L) }
        try {
            val loader = FlutterInjector.instance().flutterLoader()
            loader.startInitialization(applicationContext)
            loader.ensureInitializationCompleteAsync(applicationContext, null, handler) {
                if (active !== params) return@ensureInitializationCompleteAsync
                try {
                    val flutter = FlutterEngine(applicationContext)
                    engine = flutter
                    channel = MethodChannel(flutter.dartExecutor.binaryMessenger, "ku_todo/widget_date_refresh").apply {
                        setMethodCallHandler { call, result ->
                            if (call.method == "finished") {
                                val success = call.argument<Boolean>("success") == true
                                result.success(null)
                                // Dart에 응답을 전달한 다음 엔진을 해제한다.
                                handler.post { finishJob(params, success, startedDate) }
                            } else result.notImplemented()
                        }
                    }
                    flutter.dartExecutor.executeDartEntrypoint(
                        DartExecutor.DartEntrypoint(loader.findAppBundlePath(), "widgetDateRefresh"))
                } catch (error: Exception) {
                    Log.e("WidgetDateRefresh", "Cannot start refresh engine", error)
                    finishJob(params, false, startedDate)
                }
            }
        } catch (error: Exception) {
            Log.e("WidgetDateRefresh", "Cannot initialize Flutter", error)
            finishJob(params, false, startedDate)
        }
        return true
    }

    private fun finishJob(params: JobParameters, success: Boolean, startedDate: String) {
        if (active !== params) return
        if (success) HomeWidgetPlugin.getData(this).edit()
            .putString(WidgetDateRefresh.DATE_KEY, startedDate).apply()
        Log.i("WidgetDateRefresh", "Background refresh finished: success=$success date=$startedDate")
        release()
        WidgetDateRefresh.schedule(this)
        jobFinished(params, !success)
        // 작업 중 자정/시간대가 바뀌었으면 새 날짜로 한 번 더 조회한다.
        if (success && startedDate != WidgetDateRefresh.dateKey()) WidgetDateRefresh.request(this)
    }

    private fun release() {
        active = null
        timeout?.let { handler.removeCallbacks(it) }
        timeout = null
        channel?.setMethodCallHandler(null)
        channel = null
        engine?.destroy()
        engine = null
    }

    override fun onStopJob(params: JobParameters): Boolean {
        release()
        return WidgetDateRefresh.hasWidgets(this)
    }

    override fun onDestroy() {
        release()
        super.onDestroy()
    }
}
