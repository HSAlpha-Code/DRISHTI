import 'package:flutter/material.dart';
import '../widgets/common_ui.dart';

class LandingScreen extends StatelessWidget {
  final VoidCallback onSelectNgoPortal;
  final VoidCallback onSelectNgoRegister;
  final VoidCallback onSelectAdminPortal;
  final VoidCallback onSelectInspectorPortal;

  const LandingScreen({
    super.key,
    required this.onSelectNgoPortal,
    required this.onSelectNgoRegister,
    required this.onSelectAdminPortal,
    required this.onSelectInspectorPortal,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GovColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Government Ribbon
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              color: GovColors.deepNavy,
              child: Row(
                children: [
                  const Icon(Icons.flag, color: Colors.orange, size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'GOVERNMENT OF INDIA • MINISTRY OF SOCIAL JUSTICE & EMPOWERMENT',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Hero Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
              decoration: const BoxDecoration(
                color: GovColors.navy,
                border: Border(
                  bottom: BorderSide(color: Color(0xFF1E3A8A), width: 3),
                ),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.account_balance,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'DRISHTI',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Centralized NGO / Project Monitoring & Geo-Locked Inspection Platform',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF93C5FD),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Integrated Computer Vision • Geo-Fence Verified • Cryptographic SHA-256 Audit Trail',
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(0xFFE2E8F0),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Portal Selection Cards
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Portal Access',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: GovColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Please choose your authorized portal category to proceed with official credentials',
                        style: TextStyle(fontSize: 13, color: GovColors.textMuted),
                      ),
                      const SizedBox(height: 24),

                      // 3 Cards Layout
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth >= 850;
                          if (isWide) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildNgoCard()),
                                const SizedBox(width: 20),
                                Expanded(child: _buildAdminCard()),
                                const SizedBox(width: 20),
                                Expanded(child: _buildInspectorCard()),
                              ],
                            );
                          } else {
                            return Column(
                              children: [
                                _buildNgoCard(),
                                const SizedBox(height: 16),
                                _buildAdminCard(),
                                const SizedBox(height: 16),
                                _buildInspectorCard(),
                              ],
                            );
                          }
                        },
                      ),

                      const SizedBox(height: 48),

                      // Security & Integrity Notice Banner
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: GovColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: GovColors.border),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.security, color: GovColors.navy, size: 28),
                            SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Government Audit Standards & Geo-Fencing Compliance',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: GovColors.textDark,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'All inspection submissions undergo SHA-256 cryptographic hashing and hardware GPS coordinate matching. Unauthorized access is strictly logged.',
                                    style: TextStyle(fontSize: 11, color: GovColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNgoCard() {
    return _buildPortalCard(
      title: 'NGO / Institute Portal',
      subtitle: 'For registered NGOs, Trust entities, and Project Administrators',
      icon: Icons.corporate_fare,
      badge: 'SELF-SERVICE',
      badgeColor: GovColors.slateBlue,
      features: [
        'Registration with activation key format',
        'Direct progress reporting & milestone notes',
        'Official issue reporting to MoSJE officials',
        'Beneficiary and grant disbursement tracking',
      ],
      primaryButtonText: 'Access NGO Dashboard',
      onPrimaryTap: onSelectNgoPortal,
      secondaryButtonText: 'Register New Organization',
      onSecondaryTap: onSelectNgoRegister,
    );
  }

  Widget _buildAdminCard() {
    return _buildPortalCard(
      title: 'Ministry Admin Portal',
      subtitle: 'For MoSJE Officers, Joint Secretaries, and Audit Bureau',
      icon: Icons.admin_panel_settings,
      badge: 'RESTRICTED',
      badgeColor: GovColors.navy,
      features: [
        'National overview with 5 core metrics',
        'Interactive geographic India map pins',
        'Funding utilization, status & audit charts',
        'Project drill-down with CCTV & AI inference',
      ],
      primaryButtonText: 'Launch Admin Console',
      onPrimaryTap: onSelectAdminPortal,
    );
  }

  Widget _buildInspectorCard() {
    return _buildPortalCard(
      title: 'Inspector Field Portal',
      subtitle: 'For flying squad auditors and on-site verification teams',
      icon: Icons.verified_user,
      badge: 'GEO-LOCKED',
      badgeColor: GovColors.green,
      features: [
        'Mandatory hardware GPS proximity verification',
        'Category-wise checklist with EXIF metadata check',
        'Photo evidence submission with site coordinate stamp',
        'SHA-256 tamper-proof report cryptographic signing',
      ],
      primaryButtonText: 'Enter Inspector Portal',
      onPrimaryTap: onSelectInspectorPortal,
    );
  }

  Widget _buildPortalCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String badge,
    required Color badgeColor,
    required List<String> features,
    required String primaryButtonText,
    required VoidCallback onPrimaryTap,
    String? secondaryButtonText,
    VoidCallback? onSecondaryTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: GovColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GovColors.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: GovColors.navy.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: GovColors.navy, size: 28),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: GovColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: GovColors.textMuted, height: 1.4),
          ),
          const SizedBox(height: 20),
          const Divider(color: GovColors.border),
          const SizedBox(height: 16),
          for (final f in features) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle_outline, size: 16, color: GovColors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    f,
                    style: const TextStyle(fontSize: 12, color: GovColors.textDark, height: 1.3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPrimaryTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: GovColors.navy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                primaryButtonText,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          if (secondaryButtonText != null && onSecondaryTap != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onSecondaryTap,
                style: OutlinedButton.styleFrom(
                  foregroundColor: GovColors.slateBlue,
                  side: const BorderSide(color: GovColors.slateBlue),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  secondaryButtonText,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
