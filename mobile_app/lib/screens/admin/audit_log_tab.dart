import 'package:flutter/material.dart';
import '../../services/drishti_service.dart';
import '../../widgets/common_ui.dart';

/// Audit log tab — shows all system events: User, Role, Action, Entity, Timestamp.
class AuditLogTab extends StatelessWidget {
  const AuditLogTab({super.key});

  @override
  Widget build(BuildContext context) {
    final service = DrishtiService();
    final logs = service.auditLogs;

    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Audit Logs',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: GovColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Immutable audit trail of all system events, logins, and state changes',
              style: TextStyle(fontSize: 13, color: GovColors.textMuted),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: GovColors.border),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: constraints.maxWidth,
                          ),
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(GovColors.navy),
                            headingTextStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            columnSpacing: (constraints.maxWidth > 900) ? 28 : 16,
                            columns: const [
                              DataColumn(label: Text('User')),
                              DataColumn(label: Text('Role')),
                              DataColumn(label: Text('Action')),
                              DataColumn(label: Text('Entity / Particulars')),
                              DataColumn(label: Text('Timestamp')),
                            ],
                            rows: logs.map((log) {
                              return DataRow(cells: [
                                DataCell(Text(
                                  log.user,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                )),
                                DataCell(_roleBadge(log.role)),
                                DataCell(Text(
                                  log.action,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                  ),
                                )),
                                DataCell(
                                  ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth: (constraints.maxWidth * 0.4).clamp(240.0, 500.0),
                                    ),
                                    child: Text(
                                      log.entity,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                    ),
                                  ),
                                ),
                                DataCell(Text(
                                  log.timestamp,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: GovColors.textMuted,
                                  ),
                                )),
                              ]);
                            }).toList(),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roleBadge(String role) {
    Color bg, fg;
    switch (role) {
      case 'Admin':
        bg = GovColors.blueBg;
        fg = GovColors.slateBlue;
        break;
      case 'Inspector':
        bg = GovColors.amberBg;
        fg = GovColors.amber;
        break;
      default:
        bg = GovColors.greenBg;
        fg = GovColors.green;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        role,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
