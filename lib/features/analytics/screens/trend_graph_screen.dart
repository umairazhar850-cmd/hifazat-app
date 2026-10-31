import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/glass_card.dart';

class TrendGraphScreen extends StatefulWidget {
  const TrendGraphScreen({super.key});

  @override
  State<TrendGraphScreen> createState() => _TrendGraphScreenState();
}

class _TrendGraphScreenState extends State<TrendGraphScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // TODO (Phase 2): replace with real safety-score history per sample type,
  // pulled from firestore_service.dart (aggregate confidence/severity per test).
  List<FlSpot> get _waterSpots => const [
        FlSpot(0, 3), FlSpot(1, 2), FlSpot(2, 2.5), FlSpot(3, 1), FlSpot(4, 1.5), FlSpot(5, 0.5),
      ];
  List<FlSpot> get _milkSpots => const [
        FlSpot(0, 1), FlSpot(1, 1.2), FlSpot(2, 2), FlSpot(3, 2.3), FlSpot(4, 1.8), FlSpot(5, 1),
      ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Contamination Trends', style: AppTextStyles.heading1),
              const SizedBox(height: 4),
              const Text(
                'Lower = safer. Tracks how risk has changed over your last 6 tests.',
                style: AppTextStyles.bodySecondary,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [Tab(text: 'Water'), Tab(text: 'Milk')],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _ChartCard(spots: _waterSpots, color: const Color(0xFF2E86C1)),
              _ChartCard(spots: _milkSpots, color: const Color(0xFF8E7CC3)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  final List<FlSpot> spots;
  final Color color;
  const _ChartCard({required this.spots, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GlassCard(
        padding: const EdgeInsets.fromLTRB(12, 20, 20, 12),
        borderRadius: BorderRadius.circular(18),
        child: LineChart(
          LineChartData(
            gridData: const FlGridData(show: true, drawVerticalLine: false),
            titlesData: FlTitlesData(
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) => Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text('T${value.toInt() + 1}', style: AppTextStyles.caption),
                  ),
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: AppTextStyles.caption),
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: color,
                barWidth: 3,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.12)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
