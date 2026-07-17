package com.milo.milo

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class MiloQuickAccessWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.milo_quick_access_widget).apply {
                val title = widgetData.getString("title", null) ?: "Milo"
                val artist = widgetData.getString("artist", null) ?: "Lecteur local"
                val isPlaying = widgetData.getBoolean("is_playing", false)

                setTextViewText(R.id.quick_widget_title, title)
                setTextViewText(R.id.quick_widget_artist, artist)

                val playPauseIcon = if (isPlaying) {
                    android.R.drawable.ic_media_pause
                } else {
                    android.R.drawable.ic_media_play
                }
                setImageViewResource(R.id.quick_widget_play_pause, playPauseIcon)

                // Play/Pause
                val playPauseUri = Uri.parse("milo://toggle_playback")
                setOnClickPendingIntent(
                    R.id.quick_widget_play_pause,
                    HomeWidgetBackgroundIntent.getBroadcast(context, playPauseUri),
                )

                // Skip Previous
                val skipPrevUri = Uri.parse("milo://skip_previous")
                setOnClickPendingIntent(
                    R.id.quick_widget_skip_previous,
                    HomeWidgetBackgroundIntent.getBroadcast(context, skipPrevUri),
                )

                // Skip Next
                val skipNextUri = Uri.parse("milo://skip_next")
                setOnClickPendingIntent(
                    R.id.quick_widget_skip_next,
                    HomeWidgetBackgroundIntent.getBroadcast(context, skipNextUri),
                )

                // Raccourcis - Bibliothèque
                val libraryUri = Uri.parse("milo://open_library")
                setOnClickPendingIntent(
                    R.id.quick_widget_library,
                    HomeWidgetBackgroundIntent.getBroadcast(context, libraryUri),
                )

                // Raccourcis - Radio
                val radioUri = Uri.parse("milo://open_radio")
                setOnClickPendingIntent(
                    R.id.quick_widget_radio,
                    HomeWidgetBackgroundIntent.getBroadcast(context, radioUri),
                )

                // Raccourcis - Shuffle
                val shuffleUri = Uri.parse("milo://shuffle_all")
                setOnClickPendingIntent(
                    R.id.quick_widget_shuffle,
                    HomeWidgetBackgroundIntent.getBroadcast(context, shuffleUri),
                )

                // Raccourcis - Favoris
                val favoritesUri = Uri.parse("milo://play_favorites")
                setOnClickPendingIntent(
                    R.id.quick_widget_favorites,
                    HomeWidgetBackgroundIntent.getBroadcast(context, favoritesUri),
                )

                // Ouvrir l'app au clic sur le fond du widget
                val openAppUri = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                )
                setOnClickPendingIntent(R.id.quick_access_widget_root, openAppUri)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
