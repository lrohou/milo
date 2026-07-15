import 'package:flutter/material.dart';
import 'package:milo/core/theme/app_colors.dart';
import 'package:milo/features/dab_radio/models/dab_radio_station.dart';
import 'package:milo/features/dab_radio/presentation/dab_radio_category_detail_screen.dart';
import 'package:milo/shared/widgets/neo_brutal_container.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DabRadioCategoriesScreen extends StatelessWidget {
  const DabRadioCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Grouping logic
    final Map<String, List<DabRadioStation>> byGenre = {};
    final Map<String, List<DabRadioStation>> byCountry = {};

    for (final station in kDabRadioStations) {
      // By genre
      final genre = station.genre.trim();
      if (genre.isNotEmpty) {
        byGenre.putIfAbsent(genre, () => []).add(station);
      }

      // By country / emoji
      // Fallback a "Autres"
      String country = station.logoEmoji.trim();
      if (country.isEmpty) {
        country = 'Autres';
      }
      byCountry.putIfAbsent(country, () => []).add(station);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catégories DAB+'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSectionTitle(context, 'Par Genre'),
          const SizedBox(height: 12),
          ...byGenre.keys.toList()..sort().map((genre) {
            return _buildCategoryCard(
              context,
              title: genre,
              stations: byGenre[genre]!,
              color: AppColors.blueSky,
            );
          }),
          const SizedBox(height: 32),
          _buildSectionTitle(context, 'Par Pays / Catégorie'),
          const SizedBox(height: 12),
          ...byCountry.keys.toList()..sort().map((country) {
            return _buildCategoryCard(
              context,
              title: country,
              stations: byCountry[country]!,
              color: AppColors.greenNeon,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
          ),
    ).animate().fadeIn().moveX();
  }

  Widget _buildCategoryCard(
    BuildContext context, {
    required String title,
    required List<DabRadioStation> stations,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DabRadioCategoryDetailScreen(
                title: title,
                stations: stations,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: NeoBrutalContainer(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          backgroundColor: color,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.backgroundDeep,
                      ),
                ),
               Text(
                  '${stations.length} stations',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.backgroundDeep.withOpacity(0.8),
                      ),
                ),
            ],
          ),
        ),
      ).animate().fadeIn(delay: 100.ms).moveY(begin: 10, end: 0),
    );
  }
}
