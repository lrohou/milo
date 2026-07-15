import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milo/core/theme/app_colors.dart';
import 'package:milo/features/dab_radio/presentation/open_dab_screen.dart';
import 'package:milo/features/dab_radio/presentation/dab_radio_screen.dart';
import 'package:milo/shared/widgets/glass_card.dart';

class AccountSettingsScreen extends ConsumerWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDeep,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.cream),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Espace Comptes', style: TextStyle(color: AppColors.cream)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          GlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.yellowVivid,
                  child: Icon(Icons.person_rounded, size: 40, color: AppColors.backgroundDeep),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Profil Utilisateur',
                  style: TextStyle(color: AppColors.cream, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Configurez vos préférences et sauvegardes locales.',
                  style: TextStyle(color: AppColors.cream.withValues(alpha: 0.7)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text('Réglages', style: TextStyle(color: AppColors.yellowVivid, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildSettingTile(
            icon: Icons.palette_rounded,
            title: 'Thème de l\'application',
            subtitle: 'Dark mode activé par défaut',
            onTap: () {},
          ),
          _buildSettingTile(
            icon: Icons.radio_rounded,
            title: 'Radio DAB+',
            subtitle: 'Écouter les stations françaises en direct',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OpenDabScreen(),
                ),
              );
            },
          ),
          _buildSettingTile(
            icon: Icons.storage_rounded,
            title: 'Gestion des données',
            subtitle: 'Vider le cache ou réinitialiser les stats',
            onTap: () {},
          ),
          _buildSettingTile(
            icon: Icons.info_outline_rounded,
            title: 'À propos de Milo',
            subtitle: 'Version 1.0.0',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: AppColors.yellowVivid, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: AppColors.cream, fontSize: 16, fontWeight: FontWeight.w600)),
                  Text(subtitle, style: TextStyle(color: AppColors.cream.withValues(alpha: 0.6), fontSize: 14)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.cream, size: 16),
          ],
        ),
      ),
    );
  }
}
