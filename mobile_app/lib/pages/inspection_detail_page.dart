import 'package:flutter/material.dart';

class InspectionDetailPage extends StatefulWidget {
  final Map<String, String> task;

  const InspectionDetailPage({super.key, required this.task});

  @override
  State<InspectionDetailPage> createState() => _InspectionDetailPageState();
}

class _InspectionDetailPageState extends State<InspectionDetailPage> {
  // Step 1: Geo Check-in state
  bool isOnSiteVerified = false;
  bool isCheckingSiteLocation = false;

  // Step 2: Inspection Checklist state
  bool isFacilityOpen = false;
  bool isStudentsPresent = false;
  bool isEquipmentWorking = false;
  final TextEditingController notesController = TextEditingController();

  // Step 3: Photo proofs state
  bool hasPhoto1 = false;
  bool hasPhoto2 = false;

  // Form completion validator
  bool get isFormComplete =>
      isOnSiteVerified &&
      (isFacilityOpen || isStudentsPresent || isEquipmentWorking) &&
      hasPhoto1 &&
      hasPhoto2;

  void _verifyOnSiteLocation() async {
    setState(() {
      isCheckingSiteLocation = true;
    });

    // Simulate Location Check-in
    await Future.delayed(const Duration(milliseconds: 800));

    setState(() {
      isCheckingSiteLocation = false;
      isOnSiteVerified = true;
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Location Verified! You are On-Site.",
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xFF15803D),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _takePhoto(int photoNumber) async {
    // Simulate camera capture
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() {
      if (photoNumber == 1) hasPhoto1 = true;
      if (photoNumber == 2) hasPhoto2 = true;
    });
  }

  void _submitOfficialReport() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        scrollable: true,
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 32),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                "Report Submitted!",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F2942),
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          "Your official audit inspection report has been successfully recorded and sent to Central Command.",
          style: TextStyle(fontSize: 15, color: Color(0xFF334155)),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx); // Close dialog
                Navigator.pop(context); // Return to Dashboard
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text(
                "RETURN TO DASHBOARD",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F2942),
        elevation: 2,
        title: const Text(
          "Site Inspection",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Header: Institute Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F2942),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.task["instituteName"]!,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.task["location"]!,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF93C5FD)),
                  ),
                  const SizedBox(height: 14),
                  
                  // Map Navigation Button
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Opening Navigation Map...")),
                      );
                    },
                    icon: const Icon(Icons.navigation, color: Colors.white, size: 20),
                    label: const Text(
                      "Navigate on Map",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Step 1: On-Site Geo-Check Button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isOnSiteVerified ? const Color(0xFFDCFCE7) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isOnSiteVerified ? const Color(0xFF16A34A) : const Color(0xFFCBD5E1),
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: isOnSiteVerified ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                        child: const Text("1", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "Step 1: Check-in On-Site",
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F2942)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: isCheckingSiteLocation ? null : _verifyHardwareGpsCheck,
                      icon: isCheckingSiteLocation
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : Icon(isOnSiteVerified ? Icons.check_circle : Icons.my_location, size: 24),
                      label: Text(
                        isOnSiteVerified ? "ARRIVED ON-SITE (VERIFIED)" : "I HAVE ARRIVED ON-SITE",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isOnSiteVerified ? const Color(0xFF16A34A) : const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Step 2: Inspection Checklist & Findings
            Opacity(
              opacity: isOnSiteVerified ? 1.0 : 0.45,
              child: IgnorePointer(
                ignoring: !isOnSiteVerified,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: Color(0xFF0F2942),
                            child: Text("2", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                          SizedBox(width: 10),
                          Text(
                            "Step 2: Checklist & Findings",
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F2942)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      CheckboxListTile(
                        value: isFacilityOpen,
                        activeColor: const Color(0xFF2563EB),
                        title: const Text("Facility Open & Operational", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F2942))),
                        onChanged: (val) => setState(() => isFacilityOpen = val ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                      CheckboxListTile(
                        value: isStudentsPresent,
                        activeColor: const Color(0xFF2563EB),
                        title: const Text("Students / Beneficiaries Present", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F2942))),
                        onChanged: (val) => setState(() => isStudentsPresent = val ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                      CheckboxListTile(
                        value: isEquipmentWorking,
                        activeColor: const Color(0xFF2563EB),
                        title: const Text("Infrastructure Equipment Working", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F2942))),
                        onChanged: (val) => setState(() => isEquipmentWorking = val ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        "Additional Notes / Observations",
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F2942)),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: notesController,
                        maxLines: 2,
                        style: const TextStyle(fontSize: 15, color: Color(0xFF0F2942)),
                        decoration: InputDecoration(
                          hintText: "Enter any remarks or notes here...",
                          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Step 3: Photo Proofs
            Opacity(
              opacity: isOnSiteVerified ? 1.0 : 0.45,
              child: IgnorePointer(
                ignoring: !isOnSiteVerified,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: Color(0xFF0F2942),
                            child: Text("3", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                          SizedBox(width: 10),
                          Text(
                            "Step 3: Photo Proofs",
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F2942)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      Row(
                        children: [
                          // Photo 1 Button / Preview
                          Expanded(
                            child: Column(
                              children: [
                                Container(
                                  height: 110,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: hasPhoto1 ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: hasPhoto1 ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
                                      width: 2,
                                    ),
                                  ),
                                  child: hasPhoto1
                                      ? const Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.check_circle_rounded, color: Color(0xFF2563EB), size: 36),
                                            SizedBox(height: 4),
                                            Text("Photo 1 Captured", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                                          ],
                                        )
                                      : const Icon(Icons.camera_alt, color: Color(0xFF94A3B8), size: 36),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: () => _takePhoto(1),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                                    ),
                                    child: Text(
                                      hasPhoto1 ? "Retake Photo 1" : "Take Photo 1",
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Photo 2 Button / Preview
                          Expanded(
                            child: Column(
                              children: [
                                Container(
                                  height: 110,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: hasPhoto2 ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: hasPhoto2 ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
                                      width: 2,
                                    ),
                                  ),
                                  child: hasPhoto2
                                      ? const Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.check_circle_rounded, color: Color(0xFF2563EB), size: 36),
                                            SizedBox(height: 4),
                                            Text("Photo 2 Captured", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                                          ],
                                        )
                                      : const Icon(Icons.camera_alt, color: Color(0xFF94A3B8), size: 36),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: () => _takePhoto(2),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                                    ),
                                    child: Text(
                                      hasPhoto2 ? "Retake Photo 2" : "Take Photo 2",
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Bottom Action: Submit Official Report Button
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton.icon(
                onPressed: isFormComplete ? _submitOfficialReport : null,
                icon: const Icon(Icons.send_rounded, size: 24),
                label: const Text(
                  "SUBMIT OFFICIAL REPORT",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFCBD5E1),
                  disabledForegroundColor: const Color(0xFF94A3B8),
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _verifyHardwareGpsCheck() {
    _verifyOnSiteLocation();
  }
}
