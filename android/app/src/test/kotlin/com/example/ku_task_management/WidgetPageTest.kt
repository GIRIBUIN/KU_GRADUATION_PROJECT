package com.example.ku_task_management

import org.junit.Assert.*
import org.junit.Test

class WidgetPageTest {
    @Test fun registrationGrowthPreservesCurrentPage() {
        assertEquals(1, widgetPage(3, 3, 0).count)
        assertEquals(2, widgetPage(4, 3, 0).count)
        assertEquals(1, widgetPage(5, 5, 0).count)
        assertEquals(2, widgetPage(6, 5, 0).count)
        for (pageSize in listOf(3, 5)) {
            val before = widgetPage(pageSize + 1, pageSize, 1)
            val after = widgetPage(pageSize + 2, pageSize, before.index)
            assertEquals(1, after.index)
            assertEquals(pageSize, after.start)
            assertEquals(2, after.end - after.start)
        }
    }

    @Test fun countsAndBoundaries() {
        for (size in listOf(0, 1, 3, 4, 5, 8, 10, 12)) {
            for (pageSize in listOf(3, 5)) {
                val pages = maxOf(1, (size + pageSize - 1) / pageSize)
                val ranges = (0 until pages).map { widgetPage(size, pageSize, it) }
                assertEquals(size, ranges.sumOf { it.end - it.start })
                assertEquals((0 until size).toList(), ranges.flatMap { (it.start until it.end).toList() })
                assertTrue(ranges.all { it.end - it.start <= pageSize })
                assertEquals(0, widgetPage(size, pageSize, -1).index)
                assertEquals(pages - 1, widgetPage(size, pageSize, 100).index)
            }
        }
        assertEquals(listOf(3, 3, 2), (0..2).map { widgetPage(8, 3, it).let { it.end - it.start } })
        assertEquals(listOf(5, 5, 2), (0..2).map { widgetPage(12, 5, it).let { it.end - it.start } })
        assertEquals(0, widgetPage(1, 3, 3).index)
    }
}
