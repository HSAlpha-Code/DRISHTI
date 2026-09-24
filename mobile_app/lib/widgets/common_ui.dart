import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class GovColors {
  static const Color navy = Color(0xFF0F2942);
  static const Color deepNavy = Color(0xFF0A1C2E);
  static const Color slateBlue = Color(0xFF1E3A8A);
  static const Color lightBlue = Color(0xFF2563EB);
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color border = Color(0xFFE2E8F0);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color green = Color(0xFF166534);
  static const Color greenBg = Color(0xFFDCFCE7);
  static const Color red = Color(0xFF991B1B);
  static const Color redBg = Color(0xFFFEE2E2);
  static const Color amber = Color(0xFFB45309);
  static const Color amberBg = Color(0xFFFEF3C7);
  static const Color blueBg = Color(0xFFDBEAFE);
}

class FormatHelper {
  static String formatCurrency(double amount) {
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(2)} Cr';
    } else if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(2)} L';
    } else {
      final formatter = NumberFormat('#,##,###');
      return '₹${formatter.format(amount)}';
    }
  }

  static String formatNumber(num number) {
    final formatter = NumberFormat('#,##,###');
    return formatter.format(number);
  }
}

class CurvedStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;
  final Color? iconBgColor;
  final String? badgeText;
  final Color? badgeColor;
  final Color? badgeBgColor;
  final VoidCallback? onTap;

  const CurvedStatCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    this.iconColor = GovColors.navy,
    this.iconBgColor,
    this.badgeText,
    this.badgeColor,
    this.badgeBgColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: GovColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: GovColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconBgColor ?? GovColors.navy.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                if (badgeText != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeBgColor ?? GovColors.greenBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badgeText!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: badgeColor ?? GovColors.green,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: GovColors.textDark,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: GovColors.textMuted,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: GovColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String status;
  final bool compact;

  const StatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    Color textColor;
    Color bgColor;

    switch (status.toLowerCase()) {
      case 'verified':
      case 'passed':
      case 'completed':
      case 'online':
      case 'resolved':
        textColor = GovColors.green;
        bgColor = GovColors.greenBg;
        break;
      case 'pending':
      case 'assigned':
      case 'in review':
      case 'elevated':
      case 'partially verified':
      case 'under review':
        textColor = GovColors.amber;
        bgColor = GovColors.amberBg;
        break;
      case 'requires further action':
      case 'failed':
      case 'flagged':
      case 'critical':
      case 'offline':
      case 'suspended':
        textColor = GovColors.red;
        bgColor = GovColors.redBg;
        break;
      case 'active':
      case 'submitted':
      case 'reviewed':
        textColor = GovColors.slateBlue;
        bgColor = GovColors.blueBg;
        break;
      default:
        textColor = GovColors.textMuted;
        bgColor = const Color(0xFFF1F5F9);
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: textColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontSize: compact ? 11 : 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class BreadcrumbsTrail extends StatelessWidget {
  final List<String> crumbs;
  final ValueChanged<int>? onCrumbTap;

  const BreadcrumbsTrail({
    super.key,
    required this.crumbs,
    this.onCrumbTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < crumbs.length; i++) ...[
            if (i > 0)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Icon(Icons.chevron_right, size: 16, color: GovColors.textMuted),
              ),
            InkWell(
              onTap: onCrumbTap != null && i < crumbs.length - 1 ? () => onCrumbTap!(i) : null,
              child: Text(
                crumbs[i],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: i == crumbs.length - 1 ? FontWeight.w600 : FontWeight.w400,
                  color: i == crumbs.length - 1 ? GovColors.navy : GovColors.slateBlue,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class RoundCheckboxTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const RoundCheckboxTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: value ? GovColors.blueBg.withValues(alpha: 0.4) : GovColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: value ? GovColors.slateBlue : GovColors.border,
            width: value ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: value ? GovColors.navy : Colors.transparent,
                border: Border.all(
                  color: value ? GovColors.navy : GovColors.textMuted,
                  width: 2,
                ),
              ),
              child: value
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: value ? FontWeight.w600 : FontWeight.w500,
                      color: GovColors.textDark,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(fontSize: 12, color: GovColors.textMuted),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MoSJEAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String portalTitle;
  final String currentRole;
  final VoidCallback onSwitchPortal;

  const MoSJEAppBar({
    super.key,
    required this.portalTitle,
    required this.currentRole,
    required this.onSwitchPortal,
  });

  @override
  Size get preferredSize => const Size.fromHeight(68);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: GovColors.navy,
        border: Border(
          bottom: BorderSide(color: Color(0xFF0A1C2E), width: 2),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Emblem / Insignia Mock
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.account_balance, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'DRISHTI',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          portalTitle.toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF93C5FD),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    'Ministry of Social Justice & Empowerment • Government of India',
                    style: TextStyle(
                      color: Color(0xFFCBD5E1),
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // User Role Tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person, color: Color(0xFF93C5FD), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    currentRole,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Switch Portal button
            OutlinedButton.icon(
              onPressed: onSwitchPortal,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFF475569)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.sync_alt, size: 16),
              label: const Text('Switch Portal', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}
