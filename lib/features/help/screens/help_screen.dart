import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/glass_card.dart';

/// The scope document names a "mandatory 'Sensor Flush' protocol between
/// samples" as a stated system constraint — without it, residue from the last
/// sample cross-contaminates the next one and every reading after that is
/// suspect.
///
/// A constraint the user is never told about isn't a constraint, it's a bug
/// waiting to happen. So it gets a screen.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final thresholdPercent = (AppConstants.confidenceThreshold * 100).toInt();

    return Scaffold(
      appBar: AppBar(title: const Text('How to use HIFAZAT')),
      body: Stack(
        children: [
          const AppBackground(),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                _Section(
                  icon: Icons.cleaning_services_rounded,
                  iconColor: AppColors.unsafe,
                  title: 'Sensor Flush — do this between every sample',
                  body:
                      'This is not optional. Residue from the previous sample will '
                      'skew the next reading.\n\n'
                      '1. Rinse the probes with clean distilled water.\n'
                      '2. Shake off excess water — do not wipe the pH probe.\n'
                      '3. Rinse a second time if you just tested milk.\n'
                      '4. Wait about 30 seconds for the temperature sensor to settle.\n\n'
                      'Milk leaves fat and protein residue on the probes. Skipping the '
                      'flush after a milk test is the single most common cause of a '
                      'wrong water reading.',
                ),
                _Section(
                  icon: Icons.help_outline_rounded,
                  iconColor: AppColors.caution,
                  title: 'Why do I sometimes get "Inconclusive"?',
                  body:
                      'HIFAZAT only shows a SAFE or UNSAFE verdict when the model is at '
                      'least $thresholdPercent% confident.\n\n'
                      'Below that, it says INCONCLUSIVE and asks you to test again. This '
                      'is deliberate: a wrong "safe" is far more dangerous than no answer '
                      'at all, because it makes you drink something you would otherwise '
                      'have thrown away.\n\n'
                      'If you get inconclusive results repeatedly, the probes likely need '
                      'recalibration.',
                ),
                _Section(
                  icon: Icons.water_drop_rounded,
                  iconColor: AppColors.primary,
                  title: 'Testing water',
                  body:
                      'Fill a clean container with at least 100ml. Submerge the probes '
                      'fully — a partially submerged TDS probe reads low and can make '
                      'contaminated water look clean.\n\n'
                      'Let the sample sit for a minute if you just poured it; air bubbles '
                      'on the turbidity sensor read as suspended particles.',
                ),
                _Section(
                  icon: Icons.local_drink_rounded,
                  iconColor: AppColors.primary,
                  title: 'Testing milk',
                  body:
                      'Milk should be at room temperature, not straight from the fridge — '
                      'cold milk changes the conductivity reading and can look like it '
                      'has been watered down when it hasn\'t.\n\n'
                      'For milk you also get a purity percentage, not just SAFE/UNSAFE. '
                      'Below 95% pure usually means added water, starch, or detergent.',
                ),
                _Section(
                  icon: Icons.wifi_rounded,
                  iconColor: AppColors.textSecondary,
                  title: 'Why do I need internet?',
                  body:
                      'The AI model runs on the cloud, not on the device. The ESP32 is not '
                      'powerful enough to run it locally, which is what keeps the hardware '
                      'affordable.\n\n'
                      'That means there is no offline testing mode. You can still view your '
                      'past results without a connection, but you cannot run a new test.',
                ),
                _Section(
                  icon: Icons.storefront_rounded,
                  iconColor: AppColors.primary,
                  title: 'Tagging a vendor',
                  body:
                      'If you bought the milk or water from a registered shop, you can tag '
                      'that vendor when you test it. Your result then counts toward that '
                      'shop\'s public trust score.\n\n'
                      'Only tag a vendor if the sample genuinely came from them. Tagging '
                      'your own tap water to a shop makes the score meaningless for '
                      'everyone.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;

  const _Section({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GlassCard(
        padding: const EdgeInsets.all(18),
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(title, style: AppTextStyles.heading3),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(body, style: AppTextStyles.bodySecondary),
          ],
        ),
      ),
    );
  }
}
