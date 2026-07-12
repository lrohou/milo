package com.milo.milo

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class MiloHomeWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.milo_home_widget).apply {
                val title = widgetData.getString("title", "Milo") ?: "Milo"
                val artist = widgetData.getString("artist", "Lecteur local") ?: "Lecteur local"
                val isPlaying = widgetData.getBoolean("is_playing", false)

                setTextViewText(R.id.widget_title, title)
                setTextViewText(R.id.widget_artist, artist)

                val playPauseIcon = if (isPlaying) {
                    android.R.drawable.ic_media_pause
                } else {
                    android.R.drawable.ic_media_play
                }
                setImageViewResource(R.id.widget_play_pause, playPauseIcon)

                // Play/Pause
                val playPauseUri = Uri.parse("milo://toggle_playback")
                setOnClickPendingIntent(
                    R.id.widget_play_pause,
                    HomeWidgetBackgroundIntent.getBroadcast(
                        context,
                        playPauseUri,
                    ),
                )

                // Skip Previous
                val skipPrevUri = Uri.parse("milo://skip_previous")
                setOnClickPendingIntent(
                    R.id.widget_skip_previous,
                    HomeWidgetBackgroundIntent.getBroadcast(
                        context,
                        skipPrevUri,
                    ),
                )

                // Skip Next
                val skipNextUri = Uri.parse("milo://skip_next")
                setOnClickPendingIntent(
                    R.id.widget_skip_next,
                    HomeWidgetBackgroundIntent.getBroadcast(
                        context,
                        skipNextUri,
                    ),
                )

                // Ouvrir l'app au clic sur le fond du widget
                val openAppUri = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                )
                setOnClickPendingIntent(R.id.widget_root, openAppUri)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
