import 'package:flutter/material.dart';
import '../../services/drishti_service.dart';
import '../../widgets/common_ui.dart';
import 'inspection_review_dialog.dart';

/// Shows all inspections with columns: ID, NGO Name, Status, Result,
/// Government Review, Assigned Date, Submitted Date, View.
class InspectionListTab extends StatefulWidget {
  const InspectionListTab({super.key});

  @override
  State<InspectionListTab> createState() => _InspectionListTabState();
}

class _InspectionListTabState extends State<InspectionListTab> {
  @override
  Widget build(BuildContext context) {
    final service = DrishtiService();
    final inspections = service.inspections;

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
              'Inspection Management',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: GovColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'All field inspections dispatched across funded NGO centres',
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
                              DataColumn(label: Text('ID')),
                              DataColumn(label: Text('NGO Name')),
                              DataColumn(label: Text('Status')),
                              DataColumn(label: Text('Result')),
                              DataColumn(label: Text('Govt. Review')),
                              DataColumn(label: Text('Assigned')),
                              DataColumn(label: Text('Submitted')),
                              DataColumn(label: Text('Action')),
                            ],
                            rows: inspections.map((insp) {
                              return DataRow(cells: [
                                DataCell(Text(
                                  insp.inspectionId,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                )),
                                DataCell(Text(
                                  insp.orgName,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                )),
                                DataCell(_statusBadge(insp.status)),
                                DataCell(Text(insp.overallResult)),
                                DataCell(Text(insp.governmentReview)),
                                DataCell(Text(insp.assignedDate)),
                                DataCell(Text(insp.submittedDate ?? '—')),
                                DataCell(
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) => InspectionReviewDialog(
                                          inspection: insp,
                                          onUpdated: () => setState(() {}),
                                        ),
                                      );
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: GovColors.slateBlue,
                                      side: const BorderSide(color: GovColors.slateBlue),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                    ),
                                    icon: const Icon(Icons.visibility, size: 14),
                                    label: const Text('View', style: TextStyle(fontSize: 12)),
                                  ),
                                ),
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

  Widget _statusBadge(String status) {
    Color bg, fg;
    switch (status) {
      case 'Assigned':
        bg = GovColors.amberBg;
        fg = GovColors.amber;
        break;
      case 'Submitted':
        bg = GovColors.blueBg;
        fg = GovColors.slateBlue;
        break;
      case 'Reviewed':
        bg = GovColors.greenBg;
        fg = GovColors.green;
        break;
      default:
        bg = GovColors.border;
        fg = GovColors.textMuted;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
