//
//  MiloWidget.swift
//  MiloWidget
//
//  Widget écran d'accueil Milo pour iOS
//

import WidgetKit
import SwiftUI

// MARK: - Data Provider

struct MiloProvider: TimelineProvider {
    func placeholder(in context: Context) -> MiloEntry {
        MiloEntry(date: Date(), title: "Milo", artist: "Lecteur local", isPlaying: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (MiloEntry) -> ()) {
        let entry = loadEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MiloEntry>) -> ()) {
        let entry = loadEntry()
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
    
    private func loadEntry() -> MiloEntry {
        let userDefaults = UserDefaults(suiteName: "group.com.milo.milo")
        let title = userDefaults?.string(forKey: "title") ?? "Milo"
        let artist = userDefaults?.string(forKey: "artist") ?? "Lecteur local"
        let isPlaying = userDefaults?.bool(forKey: "is_playing") ?? false
        
        return MiloEntry(date: Date(), title: title, artist: artist, isPlaying: isPlaying)
    }
}

// MARK: - Entry

struct MiloEntry: TimelineEntry {
    let date: Date
    let title: String
    let artist: String
    let isPlaying: Bool
}

// MARK: - Widget Views

struct MiloWidgetEntryView : View {
    var entry: MiloProvider.Entry
    @Environment(\.widgetFamily) var family
    
    // Couleurs Milo
    let miloBackground = Color(red: 0.067, green: 0.067, blue: 0.067)
    let miloSurface = Color(red: 0.11, green: 0.11, blue: 0.11)
    let miloYellow = Color(red: 0.996, green: 0.894, blue: 0.008)
    let miloCream = Color(red: 1.0, green: 0.996, blue: 0.835)
    
    var body: some View {
        switch family {
        case .systemSmall:
            smallWidget
        case .systemMedium:
            mediumWidget
        default:
            mediumWidget
        }
    }
    
    // Widget petit (2x2)
    var smallWidget: some View {
        ZStack {
            miloSurface
            
            VStack(spacing: 8) {
                // Icône
                Circle()
                    .fill(miloYellow)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "music.note")
                            .foregroundColor(miloBackground)
                            .font(.system(size: 18, weight: .bold))
                    )
                
                // Titre
                Text(entry.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(miloCream)
                    .lineLimit(1)
                
                // Contrôles
                HStack(spacing: 12) {
                    Image(systemName: "backward.fill")
                        .foregroundColor(miloCream)
                    
                    Circle()
                        .fill(miloYellow)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Image(systemName: entry.isPlaying ? "pause.fill" : "play.fill")
                                .foregroundColor(miloBackground)
                                .font(.system(size: 14, weight: .bold))
                        )
                    
                    Image(systemName: "forward.fill")
                        .foregroundColor(miloCream)
                }
            }
            .padding()
        }
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(miloBackground, lineWidth: 3)
        )
    }
    
    // Widget moyen (4x2)
    var mediumWidget: some View {
        ZStack {
            miloSurface
            
            HStack(spacing: 16) {
                // Artwork placeholder
                RoundedRectangle(cornerRadius: 12)
                    .fill(miloYellow)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "music.note")
                            .foregroundColor(miloBackground)
                            .font(.system(size: 24, weight: .bold))
                    )
                
                // Infos
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(miloCream)
                        .lineLimit(1)
                    
                    Text(entry.artist)
                        .font(.system(size: 13))
                        .foregroundColor(miloCream.opacity(0.7))
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Contrôles
                HStack(spacing: 8) {
                    Image(systemName: "backward.fill")
                        .foregroundColor(miloCream)
                        .font(.system(size: 20))
                    
                    Circle()
                        .fill(miloYellow)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: entry.isPlaying ? "pause.fill" : "play.fill")
                                .foregroundColor(miloBackground)
                                .font(.system(size: 16, weight: .bold))
                        )
                    
                    Image(systemName: "forward.fill")
                        .foregroundColor(miloCream)
                        .font(.system(size: 20))
                }
            }
            .padding()
        }
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(miloBackground, lineWidth: 3)
        )
    }
}

// MARK: - Widget Configuration

@main
struct MiloWidget: Widget {
    let kind: String = "MiloWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MiloProvider()) { entry in
            MiloWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Milo Player")
        .description("Contrôlez votre musique depuis l'écran d'accueil")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Preview

struct MiloWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MiloWidgetEntryView(entry: MiloEntry(
                date: Date(),
                title: "Ma Super Chanson",
                artist: "Artiste Génial",
                isPlaying: true
            ))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            
            MiloWidgetEntryView(entry: MiloEntry(
                date: Date(),
                title: "Ma Super Chanson",
                artist: "Artiste Génial",
                isPlaying: false
            ))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
        }
    }
}
