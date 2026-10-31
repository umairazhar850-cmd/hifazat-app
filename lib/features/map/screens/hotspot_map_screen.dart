import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/glass_card.dart';

/// UI shell for the hotspot map. The real google_maps_flutter widget +
/// Firestore-backed hotspot markers get wired in during Phase 3, once you
/// have a Google Maps API key set up in AndroidManifest.xml / Info.plist.
class HotspotMapScreen extends StatelessWidget {
  const HotspotMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Contamination Map', style: AppTextStyles.heading1),
          const SizedBox(height: 4),
          const Text(
            'See reported unsafe hotspots near you',
            style: AppTextStyles.bodySecondary,
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GlassCard(
              padding: EdgeInsets.zero,
              borderRadius: BorderRadius.circular(18),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map_outlined, size: 56, color: AppColors.disabled),
                    const SizedBox(height: 12),
                    const Text('Map view will appear here', style: AppTextStyles.heading3),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Text(
                        'Wired up in Phase 3 with google_maps_flutter + your Google Maps API key, showing red/yellow/green pins from reported test results.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _legendDot(AppColors.safe, 'Safe'),
              const SizedBox(width: 16),
              _legendDot(AppColors.caution, 'Caution'),
              const SizedBox(width: 16),
              _legendDot(AppColors.unsafe, 'Unsafe'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyles.bodySecondary),
      ],
    );
  }
}
