package com.milo.milo

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class MiloControlsWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.milo_controls_widget).apply {
                val title = widgetData.getString("title", "Milo") ?: "Milo"
                val isPlaying = widgetData.getBoolean("is_playing", false)

                setTextViewText(R.id.controls_widget_title, title)

                val playPauseIcon = if (isPlaying) {
                    android.R.drawable.ic_media_pause
                } else {
                    android.R.drawable.ic_media_play
                }
                setImageViewResource(R.id.controls_widget_play_pause, playPauseIcon)

                // Play/Pause
                val playPauseUri = Uri.parse("milo://toggle_playback")
                setOnClickPendingIntent(
                    R.id.controls_widget_play_pause,
                    HomeWidgetBackgroundIntent.getBroadcast(context, playPauseUri),
                )

                // Skip Previous
                val skipPrevUri = Uri.parse("milo://skip_previous")
                setOnClickPendingIntent(
                    R.id.controls_widget_skip_previous,
                    HomeWidgetBackgroundIntent.getBroadcast(context, skipPrevUri),
                )

                // Skip Next
                val skipNextUri = Uri.parse("milo://skip_next")
                setOnClickPendingIntent(
                    R.id.controls_widget_skip_next,
                    HomeWidgetBackgroundIntent.getBroadcast(context, skipNextUri),
                )

                // Ouvrir l'app au clic sur le fond du widget
                val openAppUri = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                )
                setOnClickPendingIntent(R.id.controls_widget_root, openAppUri)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
