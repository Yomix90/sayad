package com.sayad.sayad

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/** Home-screen widget: town, fishing index, wind, waves and next tide,
 *  written by the app with HomeWidget.saveWidgetData. */
class SayadWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.sayad_widget).apply {
                setTextViewText(R.id.w_place, widgetData.getString("place", "Sayad"))
                setTextViewText(R.id.w_index, widgetData.getString("index", "–"))
                setTextViewText(R.id.w_index_label, widgetData.getString("indexLabel", ""))
                setTextViewText(R.id.w_wind, widgetData.getString("wind", "–"))
                setTextViewText(R.id.w_waves, widgetData.getString("waves", "–"))
                setTextViewText(R.id.w_tide, widgetData.getString("tide", "–"))
                setTextViewText(R.id.w_updated, widgetData.getString("updated", ""))
                setOnClickPendingIntent(
                    R.id.w_root,
                    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
                )
            }
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
