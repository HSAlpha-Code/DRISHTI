import 'package:flutter/material.dart';
import '../../services/drishti_service.dart';
import '../../widgets/common_ui.dart';
import 'ngo_video_call_dialog.dart';

class NgoProfileScreen extends StatelessWidget {
  final String orgId;
  final VoidCallback onBack;
  final ValueChanged<String> onOpenProject;

  const NgoProfileScreen({
    super.key,
    required this.orgId,
    required this.onBack,
    required this.onOpenProject,
  });

  @override
  Widget build(BuildContext context) {
    final service = DrishtiService();
    final org = service.organizations.firstWhere(
      (o) => o.id == orgId,
      orElse: () => service.organizations.first,
    );
    final projects = service.projects.where((p) => p.orgId == org.id).toList();

    final activeProjectsCount = projects.where((p) => p.status == 'Active').length;
    final totalBeneficiaries = projects.fold(0, (sum, p) => sum + p.beneficiariesRegistered);
    final totalSanctioned = projects.fold(0.0, (sum, p) => sum + p.sanctionedAmount);
    final totalReleased = projects.fold(0.0, (sum, p) => sum + p.releasedAmount);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumbs
          BreadcrumbsTrail(
            crumbs: ['Admin Console', 'NGO Registry', org.name],
            onCrumbTap: (idx) {
              if (idx <= 1) onBack();
            },
          ),
          const SizedBox(height: 16),

          // Header — responsive: side-by-side on wide, stacked on narrow
          LayoutBuilder(builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 600;
            final header = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    Text(
                      org.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: GovColors.textDark,
                      ),
                    ),
                    StatusBadge(status: org.verificationStatus),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Central Registry ID: ${org.registrationId} • ${org.city}, ${org.state}',
                  style: const TextStyle(fontSize: 13, color: GovColors.textMuted),
                ),
              ],
            );
            final videoCallButton = ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => NgoVideoCallDialog(organization: org),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: GovColors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.video_call, size: 18),
              label: const Text('Video Call Admin'),
            );

            final backButton = OutlinedButton.icon(
              onPressed: onBack,
              style: OutlinedButton.styleFrom(
                foregroundColor: GovColors.slateBlue,
                side: const BorderSide(color: GovColors.slateBlue),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Back to Registry'),
            );

            return isNarrow
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      header,
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [videoCallButton, backButton],
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: header),
                      const SizedBox(width: 12),
                      Row(
                        children: [
                          videoCallButton,
                          const SizedBox(width: 10),
                          backButton,
                        ],
                      ),
                    ],
                  );
          }),
          const SizedBox(height: 24),

          // Card 1 — Organization ID: sector, state, city, contact email, phone
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: GovColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: GovColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Organization ID & Official Particulars',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: GovColors.navy,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(status: org.sector),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: GovColors.border),
                const SizedBox(height: 16),
                LayoutBuilder(builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 560;
                  final leftCol = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _profileField('Sector Focus', org.sector),
                      _profileField('State / Union Territory', org.state),
                      _profileField('City / District', org.city),
                      _profileField('Registered Physical Address', org.fullAddress),
                    ],
                  );
                  final rightCol = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _profileField('Official Email', org.contactEmail),
                      _profileField('Contact Phone', org.contactPhone),
                      _profileField('Registration Activation Key', org.registrationId, isKey: true),
                      _profileField('Geographic Pin', '${org.latitude.toStringAsFixed(4)}° N, ${org.longitude.toStringAsFixed(4)}° E'),
                    ],
                  );
                  return isNarrow
                      ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [leftCol, rightCol])
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: leftCol),
                            const SizedBox(width: 24),
                            Expanded(child: rightCol),
                          ],
                        );
                }),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Card 2 — Financial Summary: nested small cards inside one big card showing Active Projects, Beneficiaries, Sanctioned Funds, Released Funds
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: GovColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: GovColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Financial & Scheme Performance Summary',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: GovColors.navy,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Consolidated grant utilization metrics across all active and completed central programs',
                  style: TextStyle(fontSize: 12, color: GovColors.textMuted),
                ),
                const SizedBox(height: 20),

                // 4 Nested Small Cards inside this Big Card
                LayoutBuilder(
                  builder: (context, constraints) {
                     final cols = constraints.maxWidth >= 700 ? 4 : (constraints.maxWidth >= 400 ? 2 : 1);
                     final double nestedWidth = (constraints.maxWidth - (16.0 * (cols - 1))) / cols;
                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _buildNestedStatCard(
                          title: 'Active Projects',
                          value: '$activeProjectsCount',
                          subtitle: 'Total recorded: ${projects.length}',
                          icon: Icons.account_tree,
                          width: nestedWidth,
                          color: GovColors.navy,
                        ),
                        _buildNestedStatCard(
                          title: 'Beneficiaries',
                          value: FormatHelper.formatNumber(totalBeneficiaries),
                          subtitle: 'Target verified enrollments',
                          icon: Icons.groups,
                          width: nestedWidth,
                          color: GovColors.amber,
                        ),
                        _buildNestedStatCard(
                          title: 'Sanctioned Funds',
                          value: FormatHelper.formatCurrency(totalSanctioned),
                          subtitle: 'Total grant approvals',
                          icon: Icons.currency_rupee,
                          width: nestedWidth,
                          color: GovColors.green,
                        ),
                        _buildNestedStatCard(
                          title: 'Released Funds',
                          value: FormatHelper.formatCurrency(totalReleased),
                          subtitle: 'Transferred via PFMS DBT',
                          icon: Icons.account_balance_wallet,
                          width: nestedWidth,
                          color: GovColors.slateBlue,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Card 3 — Projects list: Project name, category, status, start date, end date, "Open ->" link to project detail
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: GovColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: GovColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Registered Projects Portfolio',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: GovColors.navy,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'All sanctioned initiatives operated by this organization under MoSJE schemes',
                  style: TextStyle(fontSize: 12, color: GovColors.textMuted),
                ),
                const SizedBox(height: 16),
                const Divider(color: GovColors.border),
                const SizedBox(height: 16),

                if (projects.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('No projects linked with this organization.')),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: projects.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, idx) {
                      final prj = projects[idx];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: GovColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: GovColors.border),
                        ),
                        child: LayoutBuilder(builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 500;
                          final content = Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: GovColors.blueBg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.folder, color: GovColors.slateBlue, size: 22),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Wrap(
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        Text(prj.name,
                                            style: const TextStyle(
                                                fontSize: 14, fontWeight: FontWeight.w700, color: GovColors.textDark)),
                                        StatusBadge(status: prj.status, compact: true),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Category: ${prj.category} • ${prj.startDate} to ${prj.endDate}',
                                      style: const TextStyle(fontSize: 12, color: GovColors.textMuted),
                                    ),
                                    Text(
                                      'Sanctioned: ${FormatHelper.formatCurrency(prj.sanctionedAmount)} • ${prj.beneficiariesRegistered} Beneficiaries',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: GovColors.textDark),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isNarrow) ...[
                                const SizedBox(width: 16),
                                ElevatedButton.icon(
                                  onPressed: () => onOpenProject(prj.id),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: GovColors.navy,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  ),
                                  icon: const Icon(Icons.arrow_forward, size: 14),
                                  label: const Text('Open', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ],
                          );
                          return isNarrow
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    content,
                                    const SizedBox(height: 10),
                                    ElevatedButton.icon(
                                      onPressed: () => onOpenProject(prj.id),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: GovColors.navy,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                      ),
                                      icon: const Icon(Icons.arrow_forward, size: 14),
                                      label: const Text('Open Project', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                    ),
                                  ],
                                )
                              : content;
                        }),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileField(String label, String value, {bool isKey = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: GovColors.textMuted)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isKey ? FontWeight.w700 : FontWeight.w600,
              color: isKey ? GovColors.navy : GovColors.textDark,
              fontFamily: isKey ? 'monospace' : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNestedStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required double width,
    required Color color,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GovColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: GovColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: GovColors.textMuted),
              ),
              Icon(icon, size: 18, color: color),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: GovColors.textMuted),
          ),
        ],
      ),
    );
  }
}
