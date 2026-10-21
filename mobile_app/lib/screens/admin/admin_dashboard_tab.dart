import 'package:flutter/material.dart';
import '../../services/drishti_service.dart';
import '../../widgets/common_ui.dart';
import '../../widgets/custom_charts.dart';
import '../../widgets/india_map.dart';

class AdminDashboardTab extends StatelessWidget {
  final ValueChanged<String> onSelectNgo;

  const AdminDashboardTab({
    super.key,
    required this.onSelectNgo,
  });

  @override
  Widget build(BuildContext context) {
    final service = DrishtiService();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Section Title
          const Text(
            'Central Operations Dashboard',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: GovColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'National Scheme Audit Overview',
            style: TextStyle(fontSize: 13, color: GovColors.textMuted),
          ),
          const SizedBox(height: 24),

          // 5 Large Curved-Edge Stat Cards with Dynamic Responsive Columns
          LayoutBuilder(
            builder: (context, constraints) {
              final double width = constraints.maxWidth;
              // On wide screens (1200+), 5 cards fit evenly across the full width.
              // On medium screens (850-1200), 3 columns.
              // On small tablets/screens (550-850), 2 columns.
              // On mobile (<550), 1 column full width.
              final int cols = (width >= 1200)
                  ? 5
                  : (width >= 850)
                      ? 3
                      : (width >= 550)
                          ? 2
                          : 1;

              final double cardWidth = (width - ((cols - 1) * 16)) / cols;

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: cardWidth,
                    child: CurvedStatCard(
                      title: 'NGOs Currently Funded',
                      value: '${service.totalFundedNgos}',
                      icon: Icons.domain,
                      badgeText: 'Nationwide',
                      badgeBgColor: GovColors.blueBg,
                      badgeColor: GovColors.slateBlue,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: CurvedStatCard(
                      title: 'Projects Currently Funded',
                      value: '${service.totalFundedProjects}',
                      icon: Icons.account_tree,
                      badgeText: 'Active',
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: CurvedStatCard(
                      title: 'Funds Sanctioned',
                      value: FormatHelper.formatCurrency(service.totalFundsSanctioned),
                      icon: Icons.currency_rupee,
                      iconBgColor: GovColors.greenBg,
                      iconColor: GovColors.green,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: CurvedStatCard(
                      title: 'Beneficiaries Registered',
                      value: FormatHelper.formatNumber(service.totalBeneficiaries),
                      icon: Icons.how_to_reg,
                      iconBgColor: GovColors.amberBg,
                      iconColor: GovColors.amber,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: CurvedStatCard(
                      title: 'Active Alerts',
                      value: '${service.totalActiveAlerts}',
                      icon: Icons.warning_amber,
                      iconBgColor: GovColors.redBg,
                      iconColor: GovColors.red,
                      badgeText: 'Action Required',
                      badgeBgColor: GovColors.redBg,
                      badgeColor: GovColors.red,
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 28),

          // India Map with OpenStreetMap Integration
          IndiaMapWidget(
            organizations: service.organizations,
            projects: service.projects,
            onSelectNgo: onSelectNgo,
          ),

          const SizedBox(height: 28),

          // Charts (Scroll down)
          // 1. Column chart — "Funding Utilization": Sanctioned, Released, Spent
          FundingUtilizationChart(
            sanctioned: service.totalFundsSanctioned,
            released: service.totalFundsReleased,
            spent: service.totalFundsSpent,
          ),

          const SizedBox(height: 24),

          // 2. Doughnut chart & 3. Bar chart side-by-side or stacked responsively
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 850;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: ProjectStatusDoughnutChart(
                        completed: service.completedProjectsCount,
                        active: service.activeProjectsCount,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 5,
                      child: InspectionStatusBarChart(
                        assigned: service.inspectionsAssignedCount,
                        reviewed: service.inspectionsReviewedCount,
                        submitted: service.inspectionsSubmittedCount,
                      ),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    ProjectStatusDoughnutChart(
                      completed: service.completedProjectsCount,
                      active: service.activeProjectsCount,
                    ),
                    const SizedBox(height: 20),
                    InspectionStatusBarChart(
                      assigned: service.inspectionsAssignedCount,
                      reviewed: service.inspectionsReviewedCount,
                      submitted: service.inspectionsSubmittedCount,
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
