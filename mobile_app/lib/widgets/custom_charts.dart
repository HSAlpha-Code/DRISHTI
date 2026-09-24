import 'dart:math';
import 'package:flutter/material.dart';
import 'common_ui.dart';

class FundingUtilizationChart extends StatelessWidget {
  final double sanctioned;
  final double released;
  final double spent;

  const FundingUtilizationChart({
    super.key,
    required this.sanctioned,
    required this.released,
    required this.spent,
  });

  @override
  Widget build(BuildContext context) {
    final double maxVal = max(sanctioned, max(released, spent));
    final double safeMax = maxVal > 0 ? maxVal * 1.15 : 1.0;
    final double utilPct = released > 0 ? (spent / released) * 100 : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: GovColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GovColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Funding Utilization',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: GovColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Sanctioned vs Released vs Spent Outlay',
                    style: TextStyle(fontSize: 12, color: GovColors.textMuted),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: GovColors.blueBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Utilization: ${utilPct.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: GovColors.slateBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final double barWidth = (constraints.maxWidth * 0.16).clamp(38.0, 76.0);
              return SizedBox(
                height: 200,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildColumn(
                      label: 'Sanctioned',
                      amount: sanctioned,
                      fraction: sanctioned / safeMax,
                      color: const Color(0xFF0F2942),
                      width: barWidth,
                    ),
                    _buildColumn(
                      label: 'Released',
                      amount: released,
                      fraction: released / safeMax,
                      color: const Color(0xFF2563EB),
                      width: barWidth,
                    ),
                    _buildColumn(
                      label: 'Spent',
                      amount: spent,
                      fraction: spent / safeMax,
                      color: const Color(0xFF0D9488),
                      width: barWidth,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          const Divider(color: GovColors.border),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegend('Sanctioned', const Color(0xFF0F2942)),
              _buildLegend('Released', const Color(0xFF2563EB)),
              _buildLegend('Spent', const Color(0xFF0D9488)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColumn({
    required String label,
    required double amount,
    required double fraction,
    required Color color,
    required double width,
  }) {
    final double barHeight = max(16.0, fraction * 150.0);
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          FormatHelper.formatCurrency(amount),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: GovColors.textDark,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: width,
          height: barHeight,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: GovColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: GovColors.textMuted),
        ),
      ],
    );
  }
}

class ProjectStatusDoughnutChart extends StatelessWidget {
  final int completed;
  final int active;

  const ProjectStatusDoughnutChart({
    super.key,
    required this.completed,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final total = completed + active;
    final activePct = total > 0 ? (active / total) * 100 : 0.0;
    final completedPct = total > 0 ? (completed / total) * 100 : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: GovColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GovColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Project Status',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: GovColors.textDark,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Completed vs Active Breakdown',
            style: TextStyle(fontSize: 12, color: GovColors.textMuted),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 380;
              final double doughnutSize = (constraints.maxWidth * 0.35).clamp(110.0, 140.0);

              final doughnutWidget = SizedBox(
                width: doughnutSize,
                height: doughnutSize,
                child: CustomPaint(
                  painter: _DoughnutPainter(
                    completedRatio: total > 0 ? completed / total : 0,
                    activeRatio: total > 0 ? active / total : 0,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$total',
                          style: TextStyle(
                            fontSize: (doughnutSize * 0.17).clamp(18.0, 24.0),
                            fontWeight: FontWeight.w800,
                            color: GovColors.navy,
                          ),
                        ),
                        const Text(
                          'Total Projects',
                          style: TextStyle(fontSize: 10, color: GovColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ),
              );

              final legendWidget = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRow('Active', active, '${activePct.toStringAsFixed(0)}%', const Color(0xFF1E3A8A)),
                  const SizedBox(height: 12),
                  _buildRow('Completed', completed, '${completedPct.toStringAsFixed(0)}%', const Color(0xFF166534)),
                ],
              );

              return isNarrow
                  ? Column(
                      children: [
                        doughnutWidget,
                        const SizedBox(height: 16),
                        legendWidget,
                      ],
                    )
                  : Row(
                      children: [
                        doughnutWidget,
                        const SizedBox(width: 20),
                        Expanded(child: legendWidget),
                      ],
                    );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, int count, String pct, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: GovColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GovColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: GovColors.textDark),
            ),
          ),
          Text(
            '$count ($pct)',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}

class _DoughnutPainter extends CustomPainter {
  final double completedRatio;
  final double activeRatio;

  _DoughnutPainter({required this.completedRatio, required this.activeRatio});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 10;
    const strokeWidth = 18.0;

    final paintBg = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, paintBg);

    if (activeRatio + completedRatio <= 0) return;

    final activeAngle = 2 * pi * activeRatio;
    final completedAngle = 2 * pi * completedRatio;

    final paintActive = Paint()
      ..color = const Color(0xFF1E3A8A)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      activeAngle,
      false,
      paintActive,
    );

    final paintCompleted = Paint()
      ..color = const Color(0xFF166534)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2 + activeAngle,
      completedAngle,
      false,
      paintCompleted,
    );
  }

  @override
  bool shouldRepaint(covariant _DoughnutPainter oldDelegate) {
    return oldDelegate.completedRatio != completedRatio || oldDelegate.activeRatio != activeRatio;
  }
}

class InspectionStatusBarChart extends StatelessWidget {
  final int assigned;
  final int reviewed;
  final int submitted;

  const InspectionStatusBarChart({
    super.key,
    required this.assigned,
    required this.reviewed,
    required this.submitted,
  });

  @override
  Widget build(BuildContext context) {
    final total = assigned + reviewed + submitted;
    final safeTotal = total > 0 ? total : 1;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: GovColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GovColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Inspection Status',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: GovColors.textDark,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Assigned, Reviewed, and Submitted Tasks',
            style: TextStyle(fontSize: 12, color: GovColors.textMuted),
          ),
          const SizedBox(height: 20),
          _buildBarRow('Assigned', assigned, assigned / safeTotal, const Color(0xFFB45309)),
          const SizedBox(height: 14),
          _buildBarRow('Reviewed', reviewed, reviewed / safeTotal, const Color(0xFF166534)),
          const SizedBox(height: 14),
          _buildBarRow('Submitted', submitted, submitted / safeTotal, const Color(0xFF2563EB)),
        ],
      ),
    );
  }

  Widget _buildBarRow(String label, int count, double ratio, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: GovColors.textDark),
            ),
            Text(
              '$count tasks',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Stack(
          children: [
            Container(
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            FractionallySizedBox(
              widthFactor: max(0.04, ratio),
              child: Container(
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
