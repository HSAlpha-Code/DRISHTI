import 'package:flutter/material.dart';
import '../../widgets/common_ui.dart';
import '../../services/drishti_service.dart';

class InspectorFlowScreen extends StatefulWidget {
  const InspectorFlowScreen({super.key});

  @override
  State<InspectorFlowScreen> createState() => _InspectorFlowScreenState();
}

class _InspectorFlowScreenState extends State<InspectorFlowScreen> {
  int _currentStep = 0;
  bool _gpsVerified = false;
  bool _gpsLoading = false;
  final Map<String, String> _checklistResults = {};
  String? _photoPath;
  String _observations = '';
  String _overallResult = 'Verified';

  final List<String> _checklistItems = [
    'Infrastructure & Classrooms',
    'Biometric & Headcount Validation',
    'Sanitation & Barrier-Free Access',
    'Beneficiary Stipend Records',
    'Faculty Attendance & Credentials',
  ];

  void _next() {
    if (_currentStep < 3) {
      setState(() => _currentStep += 1);
    } else {
      _submitInspection();
    }
  }

  void _back() {
    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
    }
  }

  void _submitInspection() {
    final service = DrishtiService();
    final currentTask = service.currentInspectionTask;
    if (currentTask == null) return;

    service.submitInspection(
      inspectionId: currentTask.inspectionId,
      checklistResults: _checklistResults,
      photoWatermarkData: {
        'camera_model': 'GovAudit-Handheld-T4',
        'latitude': 28.5921,
        'longitude': 77.0460,
        'altitude_m': 218.4,
        'timestamp': DateTime.now().toIso8601String(),
      },
      overallResult: _overallResult,
      observations: _observations,
      latitude: 28.5921,
      longitude: 77.0460,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Inspection submitted successfully')),
    );
    Navigator.popUntil(context, ModalRoute.withName('/inspector'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MoSJEAppBar(
        portalTitle: 'Inspection Flow',
        currentRole: 'Inspector',
        onSwitchPortal: () => Navigator.pop(context),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Stepper(
        currentStep: _currentStep,
        onStepContinue: _next,
        onStepCancel: _back,
        steps: [
          // Step 1: GPS Verification
          Step(
            title: const Text('GPS Verification'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Verify the device location is within the allowed geo-fence.'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _gpsLoading
                      ? null
                      : () async {
                          setState(() => _gpsLoading = true);
                          final verified = await DrishtiService().verifyGps();
                          setState(() {
                            _gpsVerified = verified;
                            _gpsLoading = false;
                          });
                        },
                  child: _gpsLoading
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Verify Location'),
                ),
                const SizedBox(height: 8),
                Text(
                  _gpsVerified ? 'Location verified' : 'Not verified yet',
                  style: TextStyle(
                    color: _gpsVerified ? GovColors.green : GovColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            isActive: _currentStep >= 0,
            state: _gpsVerified ? StepState.complete : StepState.indexed,
          ),

          // Step 2: Checklist + Image
          Step(
            title: const Text('Inspection Checklist'),
            content: Column(
              children: [
                ..._checklistItems.map((item) {
                  final result = _checklistResults[item] ?? '';
                  return Card(
                    margin: const EdgeInsets.only(bottom: 6),
                    child: ListTile(
                      title: Text(item),
                      trailing: DropdownButton<String>(
                        value: result.isEmpty ? null : result,
                        hint: const Text('Select'),
                        items: const [
                          DropdownMenuItem(value: 'Pass', child: Text('Pass')),
                          DropdownMenuItem(value: 'Fail', child: Text('Fail')),
                        ],
                        onChanged: (v) {
                          setState(() => _checklistResults[item] = v ?? '');
                        },
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    // Simulated photo capture
                    setState(() => _photoPath = 'assets/evidence_snapshot.jpg');
                  },
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Capture Photo Evidence'),
                ),
                if (_photoPath != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: GovColors.green, size: 18),
                        const SizedBox(width: 6),
                        Text('Photo captured: $_photoPath'),
                      ],
                    ),
                  ),
              ],
            ),
            isActive: _currentStep >= 1,
            state: _checklistResults.length == _checklistItems.length
                ? StepState.complete
                : StepState.indexed,
          ),

          // Step 3: Review
          Step(
            title: const Text('Review'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Checklist items completed: ${_checklistResults.length}/${_checklistItems.length}'),
                Text('Pass: ${_checklistResults.values.where((v) => v == "Pass").length}'),
                Text('Fail: ${_checklistResults.values.where((v) => v == "Fail").length}'),
                Text('Photo: ${_photoPath != null ? "Uploaded" : "Not uploaded"}'),
                const SizedBox(height: 12),
                const Text('Observations', style: TextStyle(fontWeight: FontWeight.bold)),
                TextField(
                  maxLines: 3,
                  onChanged: (v) => _observations = v,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter any observations or notes',
                  ),
                ),
              ],
            ),
            isActive: _currentStep >= 2,
            state: StepState.indexed,
          ),

          // Step 4: Overall Result + Submit
          Step(
            title: const Text('Overall Result'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select the overall inspection result:'),
                const SizedBox(height: 8),
                ...['Verified', 'Partially Verified', 'Requires Further Action'].map(
                  (option) => RadioListTile<String>(
                    title: Text(option),
                    value: option,
                    groupValue: _overallResult,
                    onChanged: (v) => setState(() => _overallResult = v ?? _overallResult),
                  ),
                ),
              ],
            ),
            isActive: _currentStep >= 3,
            state: StepState.indexed,
          ),
        ],
      ),
    ),
  ),
);
  }
}

