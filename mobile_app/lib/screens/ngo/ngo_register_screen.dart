import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/drishti_service.dart';
import '../../widgets/common_ui.dart';

class NgoRegisterScreen extends StatefulWidget {
  final VoidCallback onCancel;
  final VoidCallback onRegistered;

  const NgoRegisterScreen({
    super.key,
    required this.onCancel,
    required this.onRegistered,
  });

  @override
  State<NgoRegisterScreen> createState() => _NgoRegisterScreenState();
}

class _NgoRegisterScreenState extends State<NgoRegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();

  String _selectedSector = 'Education';
  String _selectedState = 'Delhi';

  // Extensible Sectors
  final List<String> _sectors = [
    'Education',
    'Healthcare',
    'Women Welfare',
    'Rural Development',
    'Environment',
    'Disability Support',
    'Elderly Care',
    'Skill & Livelihoods',
  ];

  // Indian States
  final List<String> _states = [
    'Delhi',
    'Maharashtra',
    'Karnataka',
    'Uttar Pradesh',
    'Rajasthan',
    'Telangana',
    'Tamil Nadu',
    'West Bengal',
    'Gujarat',
    'Madhya Pradesh',
    'Bihar',
    'Punjab',
    'Haryana',
    'Odisha',
    'Kerala',
    'Assam',
  ];

  // Round-Checkbox Questionnaire: Services Provided
  final Map<String, bool> _servicesProvided = {
    'Vocational & Digital Skill Training': true,
    'Primary Healthcare & Medical Respite': false,
    'Special Needs & Barrier-Free Rehabilitation': true,
    'Women Self-Help Group Incubation': false,
    'Nutritional & Direct Stipend Distribution': true,
    'Geriatric Respite & Daycare Support': false,
    'Legal Aid & Rights Awareness Clinics': false,
  };

  // Round-Checkbox Questionnaire: Scope & Facilities
  final Map<String, bool> _facilities = {
    'Dedicated Training Classrooms / Labs': true,
    'Computer Center with High-Speed Internet': true,
    'Ramp / Barrier-Free Physical Access': true,
    'CCTV Video Surveillance Setup': true,
    'Emergency First-Aid & Medical Bay': false,
    'Fire Safety Certified Infrastructure': true,
    'In-House Counseling & Consultation Chambers': false,
    'Bio-Metric Attendance Recording Kiosks': true,
  };

  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final selectedServices = _servicesProvided.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    final selectedFacilities = _facilities.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    final org = DrishtiService().registerNgo(
      name: _nameController.text.trim(),
      sector: _selectedSector,
      city: _cityController.text.trim(),
      state: _selectedState,
      fullAddress: _addressController.text.trim(),
      contactEmail: _emailController.text.trim(),
      contactPhone: _phoneController.text.trim(),
      servicesProvided: selectedServices,
      scopeAndFacilities: selectedFacilities,
    );

    setState(() => _isSubmitting = false);

    _showRegistrationSuccessDialog(org.registrationId);
  }

  void _showRegistrationSuccessDialog(String regKey) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: GovColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: GovColors.greenBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: GovColors.green, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'Registration Successful',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: GovColors.textDark),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your organization has been provisionally registered in the Drishti Central Registry.',
                style: TextStyle(fontSize: 13, color: GovColors.textDark),
              ),
              const SizedBox(height: 16),
              const Text(
                'Auto-Generated Windows-Key Registration ID:',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: GovColors.textMuted),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: GovColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: GovColors.slateBlue, width: 1.5),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        regKey,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: GovColors.navy,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18, color: GovColors.slateBlue),
                      tooltip: 'Copy to Clipboard',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: regKey));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Registration Key copied to clipboard!')),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'This key will be utilized for matching field inspectors to your center location and sector for routine verifications.',
                style: TextStyle(fontSize: 12, color: GovColors.textMuted),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                widget.onRegistered();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: GovColors.navy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('Proceed to NGO Dashboard'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GovColors.background,
      appBar: MoSJEAppBar(
        portalTitle: 'NGO Self-Registration',
        currentRole: 'New Applicant',
        onSwitchPortal: widget.onCancel,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page Heading
                  Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Organization Registration Questionnaire',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: GovColors.textDark,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Fill in institutional details to generate your official MoSJE activation registration ID',
                              style: TextStyle(fontSize: 13, color: GovColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: widget.onCancel,
                        icon: const Icon(Icons.arrow_back, size: 16),
                        label: MediaQuery.sizeOf(context).width < 520
                            ? const Text('Back')
                            : const Text('Return to Portal'),
                        style: TextButton.styleFrom(foregroundColor: GovColors.slateBlue),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Section 1: Basic Information
                  _buildSectionCard(
                    title: '1. Basic Institutional Credentials',
                    subtitle: 'Legal entity name, sector, and official communication channels',
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: _inputDecoration('Organization / Institute Name', Icons.business),
                        validator: (v) => v == null || v.isEmpty ? 'Organization name is required' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedSector,
                              decoration: _inputDecoration('Sector Category', Icons.category),
                              items: _sectors
                                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                  .toList(),
                              onChanged: (v) => setState(() => _selectedSector = v!),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _emailController,
                              decoration: _inputDecoration('Contact Email Address', Icons.email),
                              validator: (v) => v == null || !v.contains('@') ? 'Valid email required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        decoration: _inputDecoration('Official Phone Number', Icons.phone),
                        validator: (v) => v == null || v.isEmpty ? 'Phone number is required' : null,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Section 2: Address Details
                  _buildSectionCard(
                    title: '2. Physical Location & Postal Coordinates',
                    subtitle: 'Used for GPS geofencing and inspector-assignment logic',
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _cityController,
                              decoration: _inputDecoration('City / District', Icons.location_city),
                              validator: (v) => v == null || v.isEmpty ? 'City is required' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedState,
                              decoration: _inputDecoration('State / UT', Icons.map),
                              items: _states
                                  .map((st) => DropdownMenuItem(value: st, child: Text(st)))
                                  .toList(),
                              onChanged: (v) => setState(() => _selectedState = v!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _addressController,
                        maxLines: 2,
                        decoration: _inputDecoration('Complete Physical Address (with Pincode)', Icons.place),
                        validator: (v) => v == null || v.isEmpty ? 'Complete address is required' : null,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Section 3: Detailed Round-Checkbox Questionnaire: Services Provided
                  _buildSectionCard(
                    title: '3. Services Provided (Questionnaire)',
                    subtitle: 'Check all verified services active at your center (round selection criteria)',
                    children: [
                      for (final entry in _servicesProvided.entries) ...[
                        RoundCheckboxTile(
                          title: entry.key,
                          value: entry.value,
                          onChanged: (val) => setState(() => _servicesProvided[entry.key] = val),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Section 4: Detailed Round-Checkbox Questionnaire: Scope & Facilities
                  _buildSectionCard(
                    title: '4. Physical Infrastructure & Verified Scope',
                    subtitle: 'Mandatory compliance checks verified during physical audits',
                    children: [
                      for (final entry in _facilities.entries) ...[
                        RoundCheckboxTile(
                          title: entry.key,
                          value: entry.value,
                          onChanged: (val) => setState(() => _facilities[entry.key] = val),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Submit Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: widget.onCancel,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: GovColors.textDark,
                          side: const BorderSide(color: GovColors.border),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GovColors.navy,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.vpn_key, size: 18),
                        label: Text(
                          _isSubmitting ? 'Generating Key...' : 'Submit & Generate Activation Key',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: GovColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GovColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: GovColors.textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: GovColors.textMuted),
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: GovColors.border),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 13, color: GovColors.textMuted),
      prefixIcon: Icon(icon, size: 18, color: GovColors.navy),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: GovColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: GovColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: GovColors.slateBlue, width: 1.5),
      ),
    );
  }
}
