package com.example.ku_task_management

import android.content.Context
import android.database.sqlite.SQLiteDatabase
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
class WidgetIntegrationTest {
    private val context: Context get() = RuntimeEnvironment.getApplication()
    private val prefs get() = HomeWidgetPlugin.getData(context)
    private val today = "schedule_widget_data"
    private val weekly = "weekly_schedule_widget_data"

    @Before fun reset() {
        prefs.edit().clear().commit()
        val file = context.getDatabasePath("widget-test.sqlite")
        file.parentFile!!.mkdirs()
        SQLiteDatabase.openOrCreateDatabase(file, null).use { db ->
            db.execSQL("DROP TABLE IF EXISTS tasks")
            db.execSQL("CREATE TABLE tasks (id TEXT PRIMARY KEY, status TEXT, completed_at INTEGER, updated_at INTEGER)")
            for (id in listOf("Aa", "BB", "third", "fourth", "fifth", "sixth")) {
                db.execSQL("INSERT INTO tasks VALUES (?, 'active', NULL, 0)", arrayOf(id))
            }
        }
        prefs.edit().putString("widget_db_path", file.absolutePath).commit()
        val tasks = JSONArray()
        listOf("Aa", "BB", "third", "fourth", "fifth", "sixth").forEachIndexed { i, id ->
            tasks.put(JSONObject().put("id", id).put("title", id)
                .put("sortTimestamp", i).put("isCompleted", false))
        }
        val payload = JSONObject().put("tasks", tasks).put("totalCount", 6).put("completedCount", 0).toString()
        prefs.edit().putString(today, payload).putString(weekly, payload).commit()
    }

    private fun data(key: String) = JSONObject(prefs.getString(key, null)!!)
    private fun ids(key: String): List<String> = data(key).getJSONArray("tasks").let { tasks ->
        (0 until tasks.length()).map { tasks.getJSONObject(it).getString("id") }
    }
    private fun assertDb(id: String, status: String, completed: Boolean) {
        SQLiteDatabase.openDatabase(prefs.getString("widget_db_path", null)!!, null, SQLiteDatabase.OPEN_READONLY).use { db ->
            db.rawQuery("SELECT status, completed_at, updated_at FROM tasks WHERE id = ?", arrayOf(id)).use { row ->
                assertTrue(row.moveToFirst())
                assertEquals(status, row.getString(0))
                assertEquals(!completed, row.isNull(1))
                assertTrue(row.getLong(2) > 0)
            }
        }
    }

    @Test fun toggleSynchronizesDatabaseCachesAndRetryQueues() {
        WidgetTaskCompleter.completeTask(context, "Aa", WidgetActions.WIDGET_KIND_TODAY)
        assertDb("Aa", "completed", true)
        for (key in listOf(today, weekly)) {
            assertEquals("Aa", ids(key).last())
            assertEquals(1, data(key).getInt("completedCount"))
            assertTrue(data(key).getJSONArray("tasks").getJSONObject(5).getBoolean("isCompleted"))
        }
        assertEquals("Aa", JSONArray(prefs.getString(WidgetTaskCompleter.WIDGET_PENDING_COMPLETIONS, null)).getString(0))
        WidgetTaskCompleter.completeTask(context, "Aa", WidgetActions.WIDGET_KIND_WEEKLY)
        assertDb("Aa", "active", false)
        assertEquals(ids(today), ids(weekly))
        assertEquals("Aa", ids(today).first())
        assertEquals(0, data(weekly).getInt("completedCount"))
        assertEquals(0, JSONArray(prefs.getString(WidgetTaskCompleter.WIDGET_PENDING_COMPLETIONS, null)).length())
        assertEquals("Aa", JSONArray(prefs.getString(WidgetTaskCompleter.WIDGET_PENDING_UNCOMPLETIONS, null)).getString(0))
        assertTrue(prefs.getBoolean(WidgetTaskCompleter.WIDGET_REFRESH_REQUIRED, false))
    }

    @Test fun checkboxAfterPageChangeTargetsTaskIdAndPreservesInstancePages() {
        WidgetPagination.page(prefs, 101, 6, 3)
        prefs.edit().putInt("widget_page_101", 1).putInt("widget_page_102", 0).commit()
        val page = WidgetPagination.page(prefs, 101, 6, 3)
        val clickedId = ids(today)[page.start]
        WidgetTaskCompleter.completeTask(context, clickedId, WidgetActions.WIDGET_KIND_TODAY)
        assertDb("fourth", "completed", true)
        assertEquals("fourth", ids(today).last())
        assertEquals(1, WidgetPagination.page(prefs, 101, 6, 3).index)
        assertEquals(0, WidgetPagination.page(prefs, 102, 6, 3).index)
        WidgetPagination.delete(prefs, intArrayOf(101))
        assertFalse(prefs.contains("widget_page_101"))
        assertTrue(prefs.contains("widget_page_102"))
    }

    @Test fun missingDatabaseRetainsRetryAndUnknownTaskDoesNothing() {
        prefs.edit().putString("widget_db_path", "/missing/database.sqlite").commit()
        WidgetTaskCompleter.completeTask(context, "sixth", WidgetActions.WIDGET_KIND_WEEKLY)
        assertEquals("sixth", JSONArray(prefs.getString(WidgetTaskCompleter.WIDGET_PENDING_COMPLETIONS, null)).getString(0))
        val before = prefs.all.toMap()
        WidgetTaskCompleter.completeTask(context, "unknown", WidgetActions.WIDGET_KIND_TODAY)
        assertEquals(before, prefs.all)
    }

    @Test fun equalDeadlinesRestoreCanonicalOrderAfterToggleAndUntoggle() {
        // Input is in Flutter's sortOrder order, deliberately different from ID order.
        val tasks = JSONArray()
        listOf("BB", "Aa", "third").forEachIndexed { i, id ->
            tasks.put(JSONObject().put("id", id).put("title", id)
                .put("sortTimestamp", 100).put("sortOrder", i)
                .put("createdTimestamp", 1).put("isCompleted", false))
        }
        val payload = JSONObject().put("tasks", tasks).put("completedCount", 0).put("totalCount", 3).toString()
        prefs.edit().putString(today, payload).putString(weekly, payload).commit()
        WidgetTaskCompleter.completeTask(context, "BB", WidgetActions.WIDGET_KIND_TODAY)
        assertEquals(listOf("Aa", "third", "BB"), ids(today))
        WidgetTaskCompleter.completeTask(context, "BB", WidgetActions.WIDGET_KIND_WEEKLY)
        assertEquals(listOf("BB", "Aa", "third"), ids(today))
        assertEquals(ids(today), ids(weekly))
    }

    @Test fun allCompletedRemainVisibleAndProgressReachesTotal() {
        ids(today).forEach { WidgetTaskCompleter.completeTask(context, it, WidgetActions.WIDGET_KIND_TODAY) }
        for (key in listOf(today, weekly)) {
            assertEquals(6, data(key).getJSONArray("tasks").length())
            assertEquals(6, data(key).getInt("completedCount"))
        }
    }

    @Test fun registrationIntentsSharePopupButKeepWidgetIdentity() {
        val first = WidgetTaskCreateActivity.createIntent(context, WidgetActions.WIDGET_KIND_TODAY, 101)
        val second = WidgetTaskCreateActivity.createIntent(context, WidgetActions.WIDGET_KIND_WEEKLY, 201)
        assertEquals(first.component, second.component)
        assertEquals(WidgetTaskCreateActivity::class.java.name, first.component!!.className)
        assertNotEquals(first.data, second.data)
        assertEquals("today", first.getStringExtra(WidgetActions.EXTRA_SOURCE))
        assertEquals("weekly", second.getStringExtra(WidgetActions.EXTRA_SOURCE))
        assertNotEquals(WidgetTaskCreateActivity.pendingIntent(context, "today", 101),
            WidgetTaskCreateActivity.pendingIntent(context, "today", 102))
    }

    @Test fun collidingTaskHashesHaveDistinctPendingIntents() {
        assertEquals("Aa".hashCode(), "BB".hashCode())
        for (provider in listOf(ScheduleWidgetProvider(), WeeklyScheduleWidgetProvider())) {
            val name = if (provider is ScheduleWidgetProvider) "completeTaskPendingIntent" else "toggleTaskPendingIntent"
            val method = provider.javaClass.getDeclaredMethod(name, Context::class.java, String::class.java, Int::class.javaPrimitiveType)
            method.isAccessible = true
            val first = method.invoke(provider, context, "Aa", 123)
            val second = method.invoke(provider, context, "BB", 123)
            assertNotEquals(first, second)
        }
    }
}
