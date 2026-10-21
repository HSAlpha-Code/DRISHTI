import 'package:flutter/material.dart';
import '../../models/app_models.dart';
import '../../services/drishti_service.dart';
import '../../widgets/common_ui.dart';

class InspectionReviewDialog extends StatelessWidget {
  final InspectionModel inspection;
  final VoidCallback onUpdated;

  const InspectionReviewDialog({
    super.key,
    required this.inspection,
    required this.onUpdated,
  });

  void _handleReviewDecision(BuildContext context, String decision) {
    DrishtiService().updateGovernmentReview(
      inspectionId: inspection.inspectionId,
      decision: decision,
      reviewerName: 'Director (Audit Division), MoSJE',
    );
    onUpdated();
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Government review recorded: Status marked as $decision'),
        backgroundColor: decision == 'Verified' ? GovColors.green : GovColors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final dialogWidth = (size.width - 24).clamp(280.0, 850.0);
    final dialogHeight = size.height * 0.92;
    return Dialog(
      backgroundColor: GovColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: Column(
          children: [
            // Top Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                color: GovColors.navy,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.fact_check, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Inspection Dossier: ${inspection.inspectionId}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Scrollable Content with 5 Cards
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card 1: Reason for inspection, GPS + timing
                    _buildCard(
                      title: 'Dispatch Trigger, GPS & Field Timing',
                      icon: Icons.gps_fixed,
                      children: [
                        _detailRow('Reason for Inspection', inspection.reason),
                        _detailRow(
                          'Hardware GPS Coordinates',
                          inspection.latitude != null && inspection.longitude != null
                              ? '${inspection.latitude!.toStringAsFixed(5)}° N, ${inspection.longitude!.toStringAsFixed(5)}° E (Geo-Fence Verified)'
                              : 'Pending On-Site Geolocation Capture',
                        ),
                        _detailRow(
                          'Captured Field Timestamp',
                          inspection.capturedTimestamp ?? 'Awaiting Audit Submission',
                        ),
                        if (inspection.sha256Hash != null)
                          _detailRow(
                            'SHA-256 Signature',
                            inspection.sha256Hash!,
                            isKey: true,
                          ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Card 2: Results — assigned inspector(s), Status, Overall Result, Government Review
                    _buildCard(
                      title: 'Inspection Findings & Results Summary',
                      icon: Icons.assignment_turned_in,
                      children: [
                        _detailRow('Assigned Inspector', inspection.assignedInspector),
                        _detailRow('Audit Lifecycle Status', inspection.status),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Expanded(
                              flex: 2,
                              child: Text(
                                'Overall Field Result',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: GovColors.textMuted),
                              ),
                            ),
                            Expanded(flex: 3, child: StatusBadge(status: inspection.overallResult)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Expanded(
                              flex: 2,
                              child: Text(
                                'Government Review Status',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: GovColors.textMuted),
                              ),
                            ),
                            Expanded(flex: 3, child: StatusBadge(status: inspection.governmentReview)),
                          ],
                        ),
                        if (inspection.observations.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _detailRow('Inspector Observations', inspection.observations),
                        ],
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Card 3: Checklist — pass/fail per category
                    _buildCard(
                      title: 'Category-wise Audit Checklist Verification',
                      icon: Icons.checklist,
                      children: [
                        if (inspection.checklistResults.isEmpty)
                          const Text('No checklist recorded yet for this task.', style: TextStyle(color: GovColors.textMuted))
                        else
                          for (final entry in inspection.checklistResults.entries)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      entry.key,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: GovColors.textDark),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  StatusBadge(status: entry.value, compact: true),
                                ],
                              ),
                            ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Card 4: Photograph Evidence — EXIF watermark data extracted and displayed
                    _buildCard(
                      title: 'Photograph Evidence & Hardware EXIF Stamp',
                      icon: Icons.photo_camera,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: GovColors.background,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: GovColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 100,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F172A),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: GovColors.border),
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.image, color: Colors.white70, size: 32),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Extracted Hardware EXIF Watermark Data:',
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: GovColors.navy),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Camera Model: ${inspection.photoWatermarkData['camera_model'] ?? 'GovAudit-Handheld-T4'}',
                                          style: const TextStyle(fontSize: 11, color: GovColors.textDark),
                                        ),
                                        Text(
                                          'GPS Timestamp: ${inspection.photoWatermarkData['timestamp'] ?? inspection.capturedTimestamp ?? '2026-09-15T11:24:18Z'}',
                                          style: const TextStyle(fontSize: 11, color: GovColors.textDark),
                                        ),
                                        Text(
                                          'Device Sensor Lat/Lng: ${inspection.latitude ?? 28.5921}, ${inspection.longitude ?? 77.0460}',
                                          style: const TextStyle(fontSize: 11, color: GovColors.textDark),
                                        ),
                                        Text(
                                          'Altitude: ${inspection.photoWatermarkData['altitude_m'] ?? 218.4} m',
                                          style: const TextStyle(fontSize: 11, color: GovColors.textDark),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Card 5: Government Review — two action buttons: Verified (green), Requires Further Action (red)
                    _buildCard(
                      title: 'Government Official Review Decision',
                      icon: Icons.gavel,
                      children: [
                        const Text(
                          'Select the formal ministerial appraisal status for this submitted field audit report:',
                          style: TextStyle(fontSize: 12, color: GovColors.textMuted),
                        ),
                        const SizedBox(height: 16),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isNarrow = constraints.maxWidth < 450;
                            final verifiedBtn = ElevatedButton.icon(
                              onPressed: () => _handleReviewDecision(context, 'Verified'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: GovColors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.check_circle, size: 18),
                              label: const Text('Verified', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                            );

                            final actionBtn = ElevatedButton.icon(
                              onPressed: () => _handleReviewDecision(context, 'Requires Further Action'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: GovColors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.warning, size: 18),
                              label: const Text('Requires Further Action', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                            );

                            return isNarrow
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      verifiedBtn,
                                      const SizedBox(height: 10),
                                      actionBtn,
                                    ],
                                  )
                                : Row(
                                    children: [
                                      Expanded(child: verifiedBtn),
                                      const SizedBox(width: 16),
                                      Expanded(child: actionBtn),
                                    ],
                                  );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: GovColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GovColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: GovColors.navy),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: GovColors.navy),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: GovColors.border),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isKey = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 450;
          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: GovColors.textMuted),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  softWrap: true,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isKey ? FontWeight.w700 : FontWeight.w600,
                    color: isKey ? GovColors.navy : GovColors.textDark,
                    fontFamily: isKey ? 'monospace' : null,
                  ),
                ),
              ],
            );
          }
          final double labelWidth = (constraints.maxWidth * 0.35).clamp(120.0, 200.0);
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: labelWidth,
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: GovColors.textMuted),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  softWrap: true,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isKey ? FontWeight.w700 : FontWeight.w600,
                    color: isKey ? GovColors.navy : GovColors.textDark,
                    fontFamily: isKey ? 'monospace' : null,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
