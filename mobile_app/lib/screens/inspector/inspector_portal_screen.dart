import 'package:flutter/material.dart';
import '../../widgets/common_ui.dart';
import '../../services/drishti_service.dart';

class InspectorPortalScreen extends StatelessWidget {
  const InspectorPortalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = DrishtiService();

    return Scaffold(
      appBar: MoSJEAppBar(
        portalTitle: 'Inspector Portal',
        currentRole: 'Inspector',
        onSwitchPortal: () => Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false),
      ),
      body: ListenableBuilder(
        listenable: service,
        builder: (context, _) {
          final currentTask = service.currentInspectionTask;
          final pastInspections = service.pastInspections;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                if (currentTask != null) ...[
                  const Text(
                    'Current Assigned Task',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: GovColors.navy),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 600;
                          final infoBlock = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.assignment, color: GovColors.navy, size: 22),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      currentTask.projectName,
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${currentTask.orgName} — ${currentTask.reason}',
                                style: const TextStyle(fontSize: 13, color: GovColors.textDark),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Assigned: ${currentTask.assignedDate}',
                                style: const TextStyle(fontSize: 12, color: GovColors.textMuted),
                              ),
                            ],
                          );

                          final beginBtn = ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: GovColors.navy,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => Navigator.pushNamed(context, '/inspector/flow'),
                            icon: const Icon(Icons.play_arrow, size: 18),
                            label: const Text('Begin Inspection'),
                          );

                          return isNarrow
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    infoBlock,
                                    const SizedBox(height: 12),
                                    beginBtn,
                                  ],
                                )
                              : Row(
                                  children: [
                                    Expanded(child: infoBlock),
                                    const SizedBox(width: 16),
                                    beginBtn,
                                  ],
                                );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                const Text(
                  'Past Inspections',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: GovColors.navy),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: pastInspections.isEmpty
                      ? const Center(child: Text('No past inspections yet.'))
                      : ListView.builder(
                          itemCount: pastInspections.length,
                          itemBuilder: (context, index) {
                            final insp = pastInspections[index];
                            return Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: const BorderSide(color: GovColors.border),
                              ),
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: Icon(
                                  insp.overallResult == 'Verified' ? Icons.check_circle : Icons.warning_amber_rounded,
                                  color: insp.overallResult == 'Verified' ? GovColors.green : GovColors.amber,
                                ),
                                title: Text(insp.projectName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text(
                                  '${insp.orgName} — ${insp.overallResult}\nSubmitted: ${insp.submittedDate ?? "—"}',
                                ),
                                isThreeLine: true,
                                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                                onTap: () {},
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  ),
);
  }
}
