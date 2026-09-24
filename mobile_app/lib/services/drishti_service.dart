import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import '../models/app_models.dart';

class DrishtiService extends ChangeNotifier {
  static final DrishtiService _instance = DrishtiService._internal();
  factory DrishtiService() => _instance;

  DrishtiService._internal() {
    _initializeData();
  }

  // Collections
  final List<OrganizationModel> _organizations = [];
  final List<ProjectModel> _projects = [];
  final List<FundingModel> _fundings = [];
  final List<ExpenseModel> _expenses = [];
  final List<BeneficiaryModel> _beneficiaries = [];
  final List<DocumentModel> _documents = [];
  final List<CameraModel> _cameras = [];
  final List<AlertModel> _alerts = [];
  final List<InspectionModel> _inspections = [];
  final List<AuditLogModel> _auditLogs = [];
  final List<IssueReportModel> _issueReports = [];
  final List<ProgressReportModel> _progressReports = [];

  // Getters
  List<OrganizationModel> get organizations => List.unmodifiable(_organizations);
  List<ProjectModel> get projects => List.unmodifiable(_projects);
  List<FundingModel> get fundings => List.unmodifiable(_fundings);
  List<ExpenseModel> get expenses => List.unmodifiable(_expenses);
  List<BeneficiaryModel> get beneficiaries => List.unmodifiable(_beneficiaries);
  List<DocumentModel> get documents => List.unmodifiable(_documents);
  List<CameraModel> get cameras => List.unmodifiable(_cameras);
  List<AlertModel> get alerts => List.unmodifiable(_alerts);
  List<InspectionModel> get inspections => List.unmodifiable(_inspections);
  List<AuditLogModel> get auditLogs => List.unmodifiable(_auditLogs);
  List<IssueReportModel> get issueReports => List.unmodifiable(_issueReports);
  List<ProgressReportModel> get progressReports => List.unmodifiable(_progressReports);

  // Inspection getters for UI
  InspectionModel? get currentInspectionTask {
    final matches = _inspections.where(
      (i) => i.status == 'Assigned' || i.status == 'In Progress',
    );
    return matches.isEmpty ? null : matches.first;
  }

  // Simulated GPS verification — always returns true for demo
  Future<bool> verifyGps() async {
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }

  List<InspectionModel> get pastInspections => _inspections
      .where((i) => i.status == 'Submitted' || i.status == 'Reviewed')
      .toList();

  // Stats
  int get totalFundedNgos => _organizations.where((o) => _projects.any((p) => p.orgId == o.id && p.status == 'Active')).length;
  int get totalFundedProjects => _projects.where((p) => p.status == 'Active').length;
  double get totalFundsSanctioned => _projects.fold(0.0, (sum, p) => sum + p.sanctionedAmount);
  double get totalFundsReleased => _projects.fold(0.0, (sum, p) => sum + p.releasedAmount);
  double get totalFundsSpent => _projects.fold(0.0, (sum, p) => sum + p.spentAmount);
  int get totalBeneficiaries => _projects.fold(0, (sum, p) => sum + p.beneficiariesRegistered);
  int get totalActiveAlerts => _alerts.where((a) => a.status == 'Open').length;

  int get completedProjectsCount => _projects.where((p) => p.status == 'Completed').length;
  int get activeProjectsCount => _projects.where((p) => p.status == 'Active').length;

  int get inspectionsAssignedCount => _inspections.where((i) => i.status == 'Assigned' || i.status == 'In Progress').length;
  int get inspectionsSubmittedCount => _inspections.where((i) => i.status == 'Submitted').length;
  int get inspectionsReviewedCount => _inspections.where((i) => i.status == 'Reviewed').length;

  // Active NGO context for NGO portal
  String currentNgoId = 'NGO-DEL-01';
  OrganizationModel get currentNgo => _organizations.firstWhere(
        (o) => o.id == currentNgoId,
        orElse: () => _organizations.first,
      );

  // Key generator: Windows activation style (e.g. XXXXX-XXXXX-XXXXX-XXXXX-XXXXX)
  static String generateWindowsStyleKey([String prefix = '']) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    final parts = <String>[];
    for (int i = 0; i < 5; i++) {
      if (i == 0 && prefix.isNotEmpty) {
        String chunk = prefix.toUpperCase();
        while (chunk.length < 5) {
          chunk += chars[random.nextInt(chars.length)];
        }
        parts.add(chunk.substring(0, 5));
      } else {
        final chunk = StringBuffer();
        for (int j = 0; j < 5; j++) {
          chunk.write(chars[random.nextInt(chars.length)]);
        }
        parts.add(chunk.toString());
      }
    }
    return parts.join('-');
  }

  // SHA-256 cryptographic utility
  static String computeSha256(String data) {
    final bytes = utf8.encode(data);
    return sha256.convert(bytes).toString();
  }

  // Distance calculator (Haversine formula in meters)
  static double calculateDistanceMeters(double lat1, double lon1, double lat2, double lon2) {
    const double r = 6371000; // Earth radius in meters
    final double phi1 = lat1 * pi / 180;
    final double phi2 = lat2 * pi / 180;
    final double deltaPhi = (lat2 - lat1) * pi / 180;
    final double deltaLambda = (lon2 - lon1) * pi / 180;

    final double a = sin(deltaPhi / 2) * sin(deltaPhi / 2) +
        cos(phi1) * cos(phi2) * sin(deltaLambda / 2) * sin(deltaLambda / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return r * c;
  }

  // NGO Registration
  OrganizationModel registerNgo({
    required String name,
    required String sector,
    required String city,
    required String state,
    required String fullAddress,
    required String contactEmail,
    required String contactPhone,
    required List<String> servicesProvided,
    required List<String> scopeAndFacilities,
    double latitude = 28.6139,
    double longitude = 77.2090,
  }) {
    final regId = generateWindowsStyleKey(name.length >= 4 ? name.substring(0, 4) : 'NGO');
    final org = OrganizationModel(
      id: 'NGO-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      registrationId: regId,
      sector: sector,
      city: city,
      state: state,
      fullAddress: fullAddress,
      contactEmail: contactEmail,
      contactPhone: contactPhone,
      verificationStatus: 'Pending',
      servicesProvided: servicesProvided,
      scopeAndFacilities: scopeAndFacilities,
      latitude: latitude,
      longitude: longitude,
    );

    _organizations.add(org);
    currentNgoId = org.id;

    addAuditLog(
      user: name,
      role: 'NGO Officer',
      action: 'NGO_SELF_REGISTERED',
      entity: '${org.name} ($regId)',
    );

    notifyListeners();
    return org;
  }

  // Add Funding
  void addFunding({
    required String projectId,
    required String source,
    required String stage,
    required double amount,
    required String date,
    required String purpose,
    required String reference,
  }) {
    final funding = FundingModel(
      id: 'FND-${DateTime.now().millisecondsSinceEpoch}',
      projectId: projectId,
      source: source,
      stage: stage,
      amount: amount,
      date: date,
      purpose: purpose,
      reference: reference,
    );
    _fundings.add(funding);

    // Update project released or sanctioned amount
    final idx = _projects.indexWhere((p) => p.id == projectId);
    if (idx != -1) {
      final p = _projects[idx];
      if (stage == 'Sanctioned') {
        _projects[idx] = p.copyWith(sanctionedAmount: p.sanctionedAmount + amount);
      } else {
        _projects[idx] = p.copyWith(releasedAmount: p.releasedAmount + amount);
      }
    }

    addAuditLog(
      user: 'MoSJE Finance Division',
      role: 'Admin',
      action: 'FUNDING_DISBURSED',
      entity: 'Project $projectId - ₹${amount.toStringAsFixed(0)} ($stage)',
    );

    notifyListeners();
  }

  // Add Expense
  void addExpense({
    required String projectId,
    required String purpose,
    required double amount,
    required String vendor,
    required String date,
  }) {
    final txnId = 'TXN-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final exp = ExpenseModel(
      txnId: txnId,
      projectId: projectId,
      purpose: purpose,
      amount: amount,
      vendor: vendor,
      date: date,
      status: 'Verified',
    );
    _expenses.add(exp);

    final idx = _projects.indexWhere((p) => p.id == projectId);
    if (idx != -1) {
      final p = _projects[idx];
      _projects[idx] = p.copyWith(spentAmount: p.spentAmount + amount);
    }

    addAuditLog(
      user: 'NGO Project Finance Officer',
      role: 'NGO Officer',
      action: 'EXPENSE_RECORDED',
      entity: '$txnId: ₹${amount.toStringAsFixed(0)} for $purpose',
    );

    notifyListeners();
  }

  // Add Beneficiary
  void addBeneficiary({
    required String projectId,
    required String name,
    required int age,
    required String gender,
    required String serviceReceived,
    required String date,
  }) {
    final ben = BeneficiaryModel(
      id: 'BEN-${DateTime.now().millisecondsSinceEpoch}',
      projectId: projectId,
      name: name,
      age: age,
      gender: gender,
      serviceReceived: serviceReceived,
      date: date,
    );
    _beneficiaries.add(ben);

    final idx = _projects.indexWhere((p) => p.id == projectId);
    if (idx != -1) {
      final p = _projects[idx];
      _projects[idx] = p.copyWith(beneficiariesRegistered: p.beneficiariesRegistered + 1);
    }

    addAuditLog(
      user: 'Center Field Coordinator',
      role: 'NGO Officer',
      action: 'BENEFICIARY_REGISTERED',
      entity: '$name ($gender, $age) under $projectId',
    );

    notifyListeners();
  }

  // Issue reporting
  void reportIssue({
    required String orgId,
    required String subject,
    required String description,
    required String priority,
  }) {
    final org = _organizations.firstWhere((o) => o.id == orgId, orElse: () => _organizations.first);
    final issue = IssueReportModel(
      id: 'ISS-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      orgId: orgId,
      orgName: org.name,
      subject: subject,
      description: description,
      priority: priority,
      status: 'Submitted',
      createdAt: DateTime.now().toString().split('.')[0],
    );
    _issueReports.insert(0, issue);

    addAuditLog(
      user: org.name,
      role: 'NGO Officer',
      action: 'ISSUE_REPORTED',
      entity: '${issue.id}: $subject ($priority Priority)',
    );

    notifyListeners();
  }

  // Progress reporting
  void submitProgressReport({
    required String projectId,
    required double progressPct,
    required int beneficiariesServed,
    required String notes,
  }) {
    final prj = _projects.firstWhere((p) => p.id == projectId, orElse: () => _projects.first);
    final rep = ProgressReportModel(
      id: 'REP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      projectId: projectId,
      projectName: prj.name,
      progressPct: progressPct,
      beneficiariesServed: beneficiariesServed,
      notes: notes,
      submittedAt: DateTime.now().toString().split('.')[0],
    );
    _progressReports.insert(0, rep);

    // Update project progress
    final idx = _projects.indexWhere((p) => p.id == projectId);
    if (idx != -1) {
      _projects[idx] = _projects[idx].copyWith(
        progressPct: progressPct,
        beneficiariesRegistered: max(_projects[idx].beneficiariesRegistered, beneficiariesServed),
      );
    }

    addAuditLog(
      user: prj.orgName,
      role: 'NGO Officer',
      action: 'PROGRESS_REPORT_SUBMITTED',
      entity: '${prj.name}: ${progressPct.toStringAsFixed(0)}% completed',
    );

    notifyListeners();
  }

  // Submit completed inspection from Inspector portal
  void submitInspection({
    required String inspectionId,
    required Map<String, String> checklistResults,
    required Map<String, dynamic> photoWatermarkData,
    required String overallResult,
    required String observations,
    required double latitude,
    required double longitude,
  }) {
    final idx = _inspections.indexWhere((i) => i.inspectionId == inspectionId);
    if (idx == -1) return;

    final nowStr = DateTime.now().toIso8601String();
    final inspection = _inspections[idx];

    // Compute tamper-evident SHA-256 cryptographic signature
    final payloadToHash = jsonEncode({
      'inspectionId': inspectionId,
      'orgId': inspection.orgId,
      'checklist': checklistResults,
      'exif': photoWatermarkData,
      'result': overallResult,
      'observations': observations,
      'timestamp': nowStr,
    });
    final hashSignature = computeSha256(payloadToHash);

    _inspections[idx] = inspection.copyWith(
      status: 'Submitted',
      overallResult: overallResult,
      governmentReview: 'Pending',
      submittedDate: nowStr.split('T')[0],
      latitude: latitude,
      longitude: longitude,
      capturedTimestamp: nowStr,
      checklistResults: checklistResults,
      photoWatermarkData: photoWatermarkData,
      observations: observations,
      sha256Hash: hashSignature,
      photoUrl: 'assets/evidence_snapshot.jpg',
    );

    addAuditLog(
      user: inspection.assignedInspector,
      role: 'Inspector',
      action: 'INSPECTION_SUBMITTED_AND_SIGNED',
      entity: '${inspection.inspectionId} (${inspection.orgName}) - SHA256: ${hashSignature.substring(0, 16)}...',
    );

    notifyListeners();
  }

  // Government Review Action from Admin portal
  void updateGovernmentReview({
    required String inspectionId,
    required String decision, // Verified or Requires Further Action
    String reviewerName = 'Joint Secretary, MoSJE',
  }) {
    final idx = _inspections.indexWhere((i) => i.inspectionId == inspectionId);
    if (idx == -1) return;

    final insp = _inspections[idx];
    _inspections[idx] = insp.copyWith(
      governmentReview: decision,
      status: 'Reviewed',
    );

    addAuditLog(
      user: reviewerName,
      role: 'Admin',
      action: decision == 'Verified' ? 'GOVERNMENT_REVIEW_VERIFIED' : 'GOVERNMENT_REVIEW_FLAGGED_ACTION',
      entity: 'Inspection ${insp.inspectionId} (${insp.orgName})',
    );

    notifyListeners();
  }

  void addAuditLog({
    required String user,
    required String role,
    required String action,
    required String entity,
  }) {
    _auditLogs.insert(
      0,
      AuditLogModel(
        user: user,
        role: role,
        action: action,
        entity: entity,
        timestamp: DateTime.now().toString().split('.')[0],
      ),
    );
  }

  // Pre-seed mock data matching plan.md
  void _initializeData() {
    _organizations.addAll([
      OrganizationModel(
        id: 'NGO-DEL-01',
        name: 'Akshaya Vidya Foundation',
        registrationId: 'AKSH1-78923-DEL01-99824-MOSJE',
        sector: 'Education',
        city: 'New Delhi',
        state: 'Delhi',
        fullAddress: 'Plot 14, Institutional Area, Dwarka Sector 10, New Delhi 110075',
        contactEmail: 'director@akshayavidya.org.in',
        contactPhone: '+91 11 2808 4401',
        verificationStatus: 'Verified',
        servicesProvided: ['Skill Training', 'Vocational Education', 'Digital Lab Access', 'Special Needs Support'],
        scopeAndFacilities: ['Classrooms', 'Computer Lab', 'Library', 'Ramp Access', 'CCTV Monitoring'],
        latitude: 28.5921,
        longitude: 77.0460,
      ),
      OrganizationModel(
        id: 'NGO-MUM-02',
        name: 'Samarpan Seva Samiti',
        registrationId: 'SAMP2-89104-MUM02-44102-MOSJE',
        sector: 'Healthcare',
        city: 'Mumbai',
        state: 'Maharashtra',
        fullAddress: '88/B, Swami Vivekananda Road, Bandra East, Mumbai 400051',
        contactEmail: 'admin@samarpanseva.org',
        contactPhone: '+91 22 2642 8820',
        verificationStatus: 'Verified',
        servicesProvided: ['Primary Health Care', 'Physiotherapy', 'Elderly Care Day Wing', 'Nutritional Support'],
        scopeAndFacilities: ['Consultation Rooms', 'Physiotherapy Ward', 'Pharmacy', 'Wheelchair Ramps'],
        latitude: 19.0596,
        longitude: 72.8406,
      ),
      OrganizationModel(
        id: 'NGO-BLR-03',
        name: 'Pragati Gramin Vikas Trust',
        registrationId: 'PRAG3-44192-BLR03-77218-MOSJE',
        sector: 'Rural Development',
        city: 'Bengaluru',
        state: 'Karnataka',
        fullAddress: '52, 1st Cross, Indira Nagar 2nd Stage, Bengaluru 560038',
        contactEmail: 'contact@pragatitrust.org',
        contactPhone: '+91 80 2521 9901',
        verificationStatus: 'Verified',
        servicesProvided: ['Artisan Capacity Building', 'Handicrafts Training', 'Solar Energy Literacy'],
        scopeAndFacilities: ['Workshop Shed', 'Training Hall', 'Resource Center', 'Storage Unit'],
        latitude: 12.9784,
        longitude: 77.6408,
      ),
      OrganizationModel(
        id: 'NGO-LKO-04',
        name: 'Chetna Mahila Kalyan Parishad',
        registrationId: 'CHET4-66231-LKO04-33190-MOSJE',
        sector: 'Women Welfare',
        city: 'Lucknow',
        state: 'Uttar Pradesh',
        fullAddress: 'B-12, Gomti Nagar Sector 4, Lucknow 226010',
        contactEmail: 'info@chetnamahila.org',
        contactPhone: '+91 522 2398 120',
        verificationStatus: 'Verified',
        servicesProvided: ['Women Legal Aid', 'Self-Help Group Incubation', 'Tailoring Certification'],
        scopeAndFacilities: ['Counseling Chambers', 'Stitching Training Unit', 'Creche Room'],
        latitude: 26.8467,
        longitude: 80.9462,
      ),
      OrganizationModel(
        id: 'NGO-JAI-05',
        name: 'Arogya Drishti Mission',
        registrationId: 'AROG5-55190-JAI05-88301-MOSJE',
        sector: 'Healthcare',
        city: 'Jaipur',
        state: 'Rajasthan',
        fullAddress: 'C-41, Malviya Nagar Industrial Area, Jaipur 302017',
        contactEmail: 'secretary@arogyadrishti.org',
        contactPhone: '+91 141 2750 334',
        verificationStatus: 'Verified',
        servicesProvided: ['Cataract Screening', 'Free Optical Dispensary', 'Assistive Eye Care Devices'],
        scopeAndFacilities: ['Optometry Suite', 'Sterilized Procedure Room', 'Waiting Hall'],
        latitude: 26.9124,
        longitude: 75.7873,
      ),
      OrganizationModel(
        id: 'NGO-HYD-06',
        name: 'Sahayata Divyangjan Sansthan',
        registrationId: 'SAHA6-11928-HYD06-22894-MOSJE',
        sector: 'Disability Support',
        city: 'Hyderabad',
        state: 'Telangana',
        fullAddress: '7-1-29, Ameerpet Main Road, Hyderabad 500016',
        contactEmail: 'support@sahayatatrust.org',
        contactPhone: '+91 40 2374 8190',
        verificationStatus: 'Under Review',
        servicesProvided: ['Prosthetics Fitment', 'Speech Therapy', 'Braille Training'],
        scopeAndFacilities: ['Prosthetics Workshop', 'Audio-Speech Room', 'Barrier-Free Toilets'],
        latitude: 17.3850,
        longitude: 78.4867,
      ),
    ]);

    // Projects
    _projects.addAll([
      ProjectModel(
        id: 'PRJ-DEL-2025-01',
        orgId: 'NGO-DEL-01',
        orgName: 'Akshaya Vidya Foundation',
        name: 'PM-DAKSH Divyangjan Skill Center',
        category: 'Vocational Empowerment',
        status: 'Active',
        startDate: '2025-04-01',
        endDate: '2026-03-31',
        description: 'Comprehensive market-aligned vocational training in data entry, assist-tech operation, and digital services for 150 persons with disabilities under PM-DAKSH scheme.',
        sanctionedAmount: 4500000.0,
        releasedAmount: 3200000.0,
        spentAmount: 2640000.0,
        beneficiariesTarget: 150,
        beneficiariesRegistered: 142,
        progressPct: 78.0,
      ),
      ProjectModel(
        id: 'PRJ-DEL-2025-02',
        orgId: 'NGO-DEL-01',
        orgName: 'Akshaya Vidya Foundation',
        name: 'Senior Citizens Daycare & Medical Wing',
        category: 'Geriatric Welfare',
        status: 'Active',
        startDate: '2025-06-15',
        endDate: '2026-06-14',
        description: 'Providing daytime respite, cognitive recreation, and routine health checks for vulnerable elders in South West Delhi.',
        sanctionedAmount: 2800000.0,
        releasedAmount: 1900000.0,
        spentAmount: 1450000.0,
        beneficiariesTarget: 90,
        beneficiariesRegistered: 84,
        progressPct: 65.0,
      ),
      ProjectModel(
        id: 'PRJ-MUM-2025-01',
        orgId: 'NGO-MUM-02',
        orgName: 'Samarpan Seva Samiti',
        name: 'De-addiction & Psychosocial Rehab Center',
        category: 'Substance Abuse Prevention',
        status: 'Active',
        startDate: '2025-01-10',
        endDate: '2025-12-31',
        description: 'Inpatient and outpatient detoxification, psychological counseling, and occupational rehabilitation under NAPDDR scheme.',
        sanctionedAmount: 5200000.0,
        releasedAmount: 4100000.0,
        spentAmount: 3820000.0,
        beneficiariesTarget: 200,
        beneficiariesRegistered: 192,
        progressPct: 88.0,
      ),
      ProjectModel(
        id: 'PRJ-BLR-2024-01',
        orgId: 'NGO-BLR-03',
        orgName: 'Pragati Gramin Vikas Trust',
        name: 'Rural SC/ST Artisan Livelihood Program',
        category: 'Economic Empowerment',
        status: 'Completed',
        startDate: '2024-07-01',
        endDate: '2025-06-30',
        description: 'Direct craft and handloom training with market linkage for 120 rural beneficiaries in Peri-Urban Bengaluru.',
        sanctionedAmount: 3600000.0,
        releasedAmount: 3600000.0,
        spentAmount: 3580000.0,
        beneficiariesTarget: 120,
        beneficiariesRegistered: 120,
        progressPct: 100.0,
      ),
      ProjectModel(
        id: 'PRJ-LKO-2025-01',
        orgId: 'NGO-LKO-04',
        orgName: 'Chetna Mahila Kalyan Parishad',
        name: 'Destitute Women Micro-Enterprise Hub',
        category: 'Women Livelihoods',
        status: 'Active',
        startDate: '2025-05-01',
        endDate: '2026-04-30',
        description: 'Skill development in food processing, packaging, and commercial apparel tailoring for widowed and deserted women.',
        sanctionedAmount: 3100000.0,
        releasedAmount: 2200000.0,
        spentAmount: 1720000.0,
        beneficiariesTarget: 110,
        beneficiariesRegistered: 98,
        progressPct: 60.0,
      ),
      ProjectModel(
        id: 'PRJ-JAI-2025-01',
        orgId: 'NGO-JAI-05',
        orgName: 'Arogya Drishti Mission',
        name: 'Vision Restorative Eyecare Mission',
        category: 'Assistive Healthcare',
        status: 'Active',
        startDate: '2025-03-01',
        endDate: '2026-02-28',
        description: 'Free eye screenings, cataract surgeries, and distribution of corrective assistive lenses to senior citizens.',
        sanctionedAmount: 4000000.0,
        releasedAmount: 3000000.0,
        spentAmount: 2510000.0,
        beneficiariesTarget: 500,
        beneficiariesRegistered: 485,
        progressPct: 74.0,
      ),
    ]);

    // Fundings for all projects
    _fundings.addAll([
      // PRJ-DEL-2025-01: PM-DAKSH Divyangjan Skill Center
      FundingModel(
        id: 'FND-DEL01-01',
        projectId: 'PRJ-DEL-2025-01',
        source: 'MoSJE Central Scheme Grant',
        stage: 'Sanctioned',
        amount: 4500000.0,
        date: '2025-04-05',
        purpose: 'Annual operating and instructor grant under PM-DAKSH',
        reference: 'SAN-MOSJE-2025-081',
      ),
      FundingModel(
        id: 'FND-DEL01-02',
        projectId: 'PRJ-DEL-2025-01',
        source: 'MoSJE First Tranche Release',
        stage: 'Released',
        amount: 3200000.0,
        date: '2025-04-20',
        purpose: 'Q1-Q3 installment disbursement via PFMS DBT',
        reference: 'REL-PFMS-99210',
      ),

      // PRJ-DEL-2025-02: Senior Citizens Daycare & Medical Wing
      FundingModel(
        id: 'FND-DEL02-01',
        projectId: 'PRJ-DEL-2025-02',
        source: 'MoSJE Geriatric Welfare Grant',
        stage: 'Sanctioned',
        amount: 2800000.0,
        date: '2025-06-18',
        purpose: 'Elderly daycare medical clinic & cognitive recreation setup',
        reference: 'SAN-MOSJE-2025-114',
      ),
      FundingModel(
        id: 'FND-DEL02-02',
        projectId: 'PRJ-DEL-2025-02',
        source: 'MoSJE Senior Welfare Allocation',
        stage: 'Released',
        amount: 1900000.0,
        date: '2025-07-02',
        purpose: 'Tranche I clinical beds and mobility aids release',
        reference: 'REL-PFMS-99402',
      ),

      // PRJ-MUM-2025-01: De-addiction & Psychosocial Rehab Center
      FundingModel(
        id: 'FND-MUM01-01',
        projectId: 'PRJ-MUM-2025-01',
        source: 'NAPDDR Substance Prevention Grant',
        stage: 'Sanctioned',
        amount: 5200000.0,
        date: '2025-01-15',
        purpose: 'Annual operational grant for 50-bed de-addiction rehab center',
        reference: 'SAN-NAPDDR-2025-032',
      ),
      FundingModel(
        id: 'FND-MUM01-02',
        projectId: 'PRJ-MUM-2025-01',
        source: 'PFMS Central Disbursal (Tranche I)',
        stage: 'Released',
        amount: 2600000.0,
        date: '2025-02-01',
        purpose: 'Inpatient detoxification ward setup and counselor stipends',
        reference: 'REL-PFMS-88194',
      ),
      FundingModel(
        id: 'FND-MUM01-03',
        projectId: 'PRJ-MUM-2025-01',
        source: 'PFMS Central Disbursal (Tranche II)',
        stage: 'Released',
        amount: 1500000.0,
        date: '2025-06-10',
        purpose: 'Mid-term milestone release after biometric audit clearance',
        reference: 'REL-PFMS-91044',
      ),

      // PRJ-BLR-2024-01: Rural SC/ST Artisan Livelihood Program
      FundingModel(
        id: 'FND-BLR01-01',
        projectId: 'PRJ-BLR-2024-01',
        source: 'SC/ST Economic Development Fund',
        stage: 'Sanctioned',
        amount: 3600000.0,
        date: '2024-07-05',
        purpose: 'Artisan handloom weaving and direct market enablement',
        reference: 'SAN-SCST-2024-099',
      ),
      FundingModel(
        id: 'FND-BLR01-02',
        projectId: 'PRJ-BLR-2024-01',
        source: 'Full Grant Disbursal (Final)',
        stage: 'Released',
        amount: 3600000.0,
        date: '2024-08-01',
        purpose: '100% completion funding upon successful co-op registration',
        reference: 'REL-PFMS-77102',
      ),

      // PRJ-LKO-2025-01: Destitute Women Micro-Enterprise Hub
      FundingModel(
        id: 'FND-LKO01-01',
        projectId: 'PRJ-LKO-2025-01',
        source: 'MoSJE Women Livelihoods Scheme',
        stage: 'Sanctioned',
        amount: 3100000.0,
        date: '2025-05-10',
        purpose: 'Skill certification in apparel stitching and food packaging',
        reference: 'SAN-MOSJE-2025-201',
      ),
      FundingModel(
        id: 'FND-LKO01-02',
        projectId: 'PRJ-LKO-2025-01',
        source: 'First Milestone Disbursement',
        stage: 'Released',
        amount: 2200000.0,
        date: '2025-06-01',
        purpose: 'Industrial sewing units and hygienic kitchen setup',
        reference: 'REL-PFMS-94182',
      ),

      // PRJ-JAI-2025-01: Vision Restorative Eyecare Mission
      FundingModel(
        id: 'FND-JAI01-01',
        projectId: 'PRJ-JAI-2025-01',
        source: 'National Blindness & Vision Care Grant',
        stage: 'Sanctioned',
        amount: 4000000.0,
        date: '2025-03-05',
        purpose: 'Mobile cataract surgeries and assistive spectacles outreach',
        reference: 'SAN-AROGYA-2025-045',
      ),
      FundingModel(
        id: 'FND-JAI01-02',
        projectId: 'PRJ-JAI-2025-01',
        source: 'Mobile Healthcare Grant Tranche',
        stage: 'Released',
        amount: 3000000.0,
        date: '2025-04-12',
        purpose: 'Surgical consumables and outreach camp van maintenance',
        reference: 'REL-PFMS-93108',
      ),
    ]);

    // Expenses for all projects
    _expenses.addAll([
      // PRJ-DEL-2025-01
      ExpenseModel(
        txnId: 'TXN-DEL01-8801',
        projectId: 'PRJ-DEL-2025-01',
        purpose: 'Procurement of 25 Braille Displays & Screen Readers',
        amount: 625000.0,
        vendor: 'AssistTech India Pvt Ltd',
        date: '2025-05-12',
        status: 'Verified',
      ),
      ExpenseModel(
        txnId: 'TXN-DEL01-8802',
        projectId: 'PRJ-DEL-2025-01',
        purpose: 'Trainer Honorarium & Pedagogical Materials',
        amount: 420000.0,
        vendor: 'Faculty Welfare Consortium',
        date: '2025-06-28',
        status: 'Verified',
      ),
      ExpenseModel(
        txnId: 'TXN-DEL01-8803',
        projectId: 'PRJ-DEL-2025-01',
        purpose: 'Nutritional Stipend Disbursement for Trainees',
        amount: 315000.0,
        vendor: 'Direct Beneficiary DBT Account',
        date: '2025-07-30',
        status: 'Verified',
      ),
      ExpenseModel(
        txnId: 'TXN-DEL01-8804',
        projectId: 'PRJ-DEL-2025-01',
        purpose: 'CCTV Infrastructure Upgrades & Optical Broadband',
        amount: 180000.0,
        vendor: 'SecureNet Telecom Delhi',
        date: '2025-08-14',
        status: 'Pending',
      ),

      // PRJ-DEL-2025-02
      ExpenseModel(
        txnId: 'TXN-DEL02-7701',
        projectId: 'PRJ-DEL-2025-02',
        purpose: 'Hydraulic Physiotherapy Beds & Traction Units',
        amount: 380000.0,
        vendor: 'MediCare Rehab Equipment',
        date: '2025-07-15',
        status: 'Verified',
      ),
      ExpenseModel(
        txnId: 'TXN-DEL02-7702',
        projectId: 'PRJ-DEL-2025-02',
        purpose: 'Diagnostic Blood Chemistry & ECG Analyzers',
        amount: 240000.0,
        vendor: 'BioHealth Diagnostic Instruments',
        date: '2025-08-01',
        status: 'Verified',
      ),
      ExpenseModel(
        txnId: 'TXN-DEL02-7703',
        projectId: 'PRJ-DEL-2025-02',
        purpose: 'Elderly Nutritious Mid-day Meal Program (Q1)',
        amount: 420000.0,
        vendor: 'Annapurna Institutional Catering',
        date: '2025-08-25',
        status: 'Verified',
      ),
      ExpenseModel(
        txnId: 'TXN-DEL02-7704',
        projectId: 'PRJ-DEL-2025-02',
        purpose: 'Visiting Geriatrician & Nurse Honorarium',
        amount: 410000.0,
        vendor: 'Healthcare Professionals Council',
        date: '2025-09-10',
        status: 'Verified',
      ),

      // PRJ-MUM-2025-01
      ExpenseModel(
        txnId: 'TXN-MUM01-6601',
        projectId: 'PRJ-MUM-2025-01',
        purpose: 'Essential Detoxification Pharmaceuticals & Emergency Meds',
        amount: 980000.0,
        vendor: 'Sahyadri Pharma Distributors',
        date: '2025-02-18',
        status: 'Verified',
      ),
      ExpenseModel(
        txnId: 'TXN-MUM01-6602',
        projectId: 'PRJ-MUM-2025-01',
        purpose: 'Clinical Psychologist & Addiction Counselors Retainer',
        amount: 1120000.0,
        vendor: 'MindCare Clinical Services',
        date: '2025-04-10',
        status: 'Verified',
      ),
      ExpenseModel(
        txnId: 'TXN-MUM01-6603',
        projectId: 'PRJ-MUM-2025-01',
        purpose: 'Vocational Pottery & Woodwork Therapeutic Tools',
        amount: 840000.0,
        vendor: 'Artisan Crafts Workshop Mumbai',
        date: '2025-05-22',
        status: 'Verified',
      ),
      ExpenseModel(
        txnId: 'TXN-MUM01-6604',
        projectId: 'PRJ-MUM-2025-01',
        purpose: 'Pharmacy Stock Register Software & Barcode Scanners',
        amount: 180000.0,
        vendor: 'MedTech Softwares India',
        date: '2025-07-14',
        status: 'Pending',
      ),

      // PRJ-BLR-2024-01
      ExpenseModel(
        txnId: 'TXN-BLR01-5501',
        projectId: 'PRJ-BLR-2024-01',
        purpose: 'Handloom Frame Weaving Units & Fly Shuttle Sets',
        amount: 1450000.0,
        vendor: 'Karnataka Loom Machinery Works',
        date: '2024-08-15',
        status: 'Verified',
      ),
      ExpenseModel(
        txnId: 'TXN-BLR01-5502',
        projectId: 'PRJ-BLR-2024-01',
        purpose: 'Natural Mulberry Silk & Cotton Spun Yarn Bales',
        amount: 1020000.0,
        vendor: 'Mysore Silk Weavers Federation',
        date: '2024-10-04',
        status: 'Verified',
      ),
      ExpenseModel(
        txnId: 'TXN-BLR01-5503',
        projectId: 'PRJ-BLR-2024-01',
        purpose: 'Master Artisan Skill Instructor Honorarium',
        amount: 650000.0,
        vendor: 'South India Crafts Guild',
        date: '2024-12-20',
        status: 'Verified',
      ),
      ExpenseModel(
        txnId: 'TXN-BLR01-5504',
        projectId: 'PRJ-BLR-2024-01',
        purpose: 'State Exhibition Stall Booking & Market Linkage',
        amount: 460000.0,
        vendor: 'Tribal Co-op Marketing Board',
        date: '2025-03-15',
        status: 'Verified',
      ),

      // PRJ-LKO-2025-01
      ExpenseModel(
        txnId: 'TXN-LKO01-4401',
        projectId: 'PRJ-LKO-2025-01',
        purpose: '20 Heavy-Duty Industrial Overlock Sewing Machines',
        amount: 680000.0,
        vendor: 'Usha & Brother Stitching Systems',
        date: '2025-06-12',
        status: 'Verified',
      ),
      ExpenseModel(
        txnId: 'TXN-LKO01-4402',
        projectId: 'PRJ-LKO-2025-01',
        purpose: 'Commercial Spices Pulverizer & Sealed Packaging Unit',
        amount: 450000.0,
        vendor: 'AgroProcessing Machines Kanpur',
        date: '2025-07-08',
        status: 'Verified',
      ),
      ExpenseModel(
        txnId: 'TXN-LKO01-4403',
        projectId: 'PRJ-LKO-2025-01',
        purpose: 'Textile Fabric Bolts & Food Grade Raw Materials',
        amount: 340000.0,
        vendor: 'Avadh Wholesale Cooperative',
        date: '2025-08-16',
        status: 'Verified',
      ),
      ExpenseModel(
        txnId: 'TXN-LKO01-4404',
        projectId: 'PRJ-LKO-2025-01',
        purpose: 'Food Safety Hygiene Audit & FSSAI Lab Testing',
        amount: 250000.0,
        vendor: 'Central Standards Certification Lab',
        date: '2025-09-02',
        status: 'Verified',
      ),

      // PRJ-JAI-2025-01
      ExpenseModel(
        txnId: 'TXN-JAI01-3301',
        projectId: 'PRJ-JAI-2025-01',
        purpose: 'Hydrophobic Foldable Intraocular Lenses (400 Units)',
        amount: 1150000.0,
        vendor: 'Appasamy Ocular Technologies',
        date: '2025-04-20',
        status: 'Verified',
      ),
      ExpenseModel(
        txnId: 'TXN-JAI01-3302',
        projectId: 'PRJ-JAI-2025-01',
        purpose: 'Mobile Clinic Ophthalmic Slit Lamp Calibration',
        amount: 380000.0,
        vendor: 'Carl Zeiss India Meditec',
        date: '2025-05-18',
        status: 'Verified',
      ),
      ExpenseModel(
        txnId: 'TXN-JAI01-3303',
        projectId: 'PRJ-JAI-2025-01',
        purpose: 'Outreach Screening Camp Bus Fuel & Mobility Logistics',
        amount: 560000.0,
        vendor: 'Rajasthan Rural Transport Corp',
        date: '2025-06-30',
        status: 'Verified',
      ),
      ExpenseModel(
        txnId: 'TXN-JAI01-3304',
        projectId: 'PRJ-JAI-2025-01',
        purpose: 'Sterilized Surgical Drapes & Antibiotic Eye Drops',
        amount: 420000.0,
        vendor: 'Sun Life Surgicals Jaipur',
        date: '2025-08-04',
        status: 'Verified',
      ),
    ]);

    // Beneficiaries for all projects
    _beneficiaries.addAll([
      // PRJ-DEL-2025-01
      BeneficiaryModel(
        id: 'BEN-DEL01-01',
        projectId: 'PRJ-DEL-2025-01',
        name: 'Aarav Sharma',
        age: 22,
        gender: 'Male',
        serviceReceived: 'Assistive Computer Course Certificate',
        date: '2025-07-10',
      ),
      BeneficiaryModel(
        id: 'BEN-DEL01-02',
        projectId: 'PRJ-DEL-2025-01',
        name: 'Pooja Kumari',
        age: 24,
        gender: 'Female',
        serviceReceived: 'Data Entry & Office Operations Module',
        date: '2025-07-15',
      ),
      BeneficiaryModel(
        id: 'BEN-DEL01-03',
        projectId: 'PRJ-DEL-2025-01',
        name: 'Mohammed Farooq',
        age: 21,
        gender: 'Male',
        serviceReceived: 'Audio Editing & Screen Reader Tools',
        date: '2025-08-02',
      ),
      BeneficiaryModel(
        id: 'BEN-DEL01-04',
        projectId: 'PRJ-DEL-2025-01',
        name: 'Sunita Verma',
        age: 27,
        gender: 'Female',
        serviceReceived: 'Financial Literacy & Typing Certification',
        date: '2025-08-20',
      ),
      BeneficiaryModel(
        id: 'BEN-DEL01-05',
        projectId: 'PRJ-DEL-2025-01',
        name: 'Rohan Patel',
        age: 19,
        gender: 'Male',
        serviceReceived: 'Call Center Operations Skill Badge',
        date: '2025-09-05',
      ),

      // PRJ-DEL-2025-02
      BeneficiaryModel(
        id: 'BEN-DEL02-01',
        projectId: 'PRJ-DEL-2025-02',
        name: 'Kewal Krishan',
        age: 72,
        gender: 'Male',
        serviceReceived: 'Knee Osteoarthritis Physiotherapy & Daily Lunch',
        date: '2025-07-12',
      ),
      BeneficiaryModel(
        id: 'BEN-DEL02-02',
        projectId: 'PRJ-DEL-2025-02',
        name: 'Shanti Devi',
        age: 68,
        gender: 'Female',
        serviceReceived: 'Hypertension Management & Yoga Meditation',
        date: '2025-07-20',
      ),
      BeneficiaryModel(
        id: 'BEN-DEL02-03',
        projectId: 'PRJ-DEL-2025-02',
        name: 'Harish Chandra',
        age: 76,
        gender: 'Male',
        serviceReceived: 'Cognitive Memory Therapy & Assisted Walking Frame',
        date: '2025-08-05',
      ),
      BeneficiaryModel(
        id: 'BEN-DEL02-04',
        projectId: 'PRJ-DEL-2025-02',
        name: 'Kamla Rawat',
        age: 70,
        gender: 'Female',
        serviceReceived: 'Routine Ophthalmology Checkup & Reading Aids',
        date: '2025-08-18',
      ),
      BeneficiaryModel(
        id: 'BEN-DEL02-05',
        projectId: 'PRJ-DEL-2025-02',
        name: 'Bhagwan Das',
        age: 74,
        gender: 'Male',
        serviceReceived: 'Diabetes Nutritional Care & Social Respite',
        date: '2025-09-01',
      ),

      // PRJ-MUM-2025-01
      BeneficiaryModel(
        id: 'BEN-MUM01-01',
        projectId: 'PRJ-MUM-2025-01',
        name: 'Prateek Jadhav',
        age: 29,
        gender: 'Male',
        serviceReceived: 'Phase 2 Inpatient Detoxification & Counseling',
        date: '2025-03-01',
      ),
      BeneficiaryModel(
        id: 'BEN-MUM01-02',
        projectId: 'PRJ-MUM-2025-01',
        name: 'Sameer Naik',
        age: 33,
        gender: 'Male',
        serviceReceived: 'Cognitive Behavioral Therapy (12 Sessions)',
        date: '2025-04-15',
      ),
      BeneficiaryModel(
        id: 'BEN-MUM01-03',
        projectId: 'PRJ-MUM-2025-01',
        name: 'Anand Gawde',
        age: 26,
        gender: 'Male',
        serviceReceived: 'Vocational Carpentry Apprenticeship Placement',
        date: '2025-05-10',
      ),
      BeneficiaryModel(
        id: 'BEN-MUM01-04',
        projectId: 'PRJ-MUM-2025-01',
        name: 'Rahul Sawant',
        age: 31,
        gender: 'Male',
        serviceReceived: 'Family Reconciliation Therapy & Relapse Prevention',
        date: '2025-06-25',
      ),
      BeneficiaryModel(
        id: 'BEN-MUM01-05',
        projectId: 'PRJ-MUM-2025-01',
        name: 'Vinod Tambe',
        age: 35,
        gender: 'Male',
        serviceReceived: 'Outpatient Follow-up & Sobriety Peer Support',
        date: '2025-08-04',
      ),

      // PRJ-BLR-2024-01
      BeneficiaryModel(
        id: 'BEN-BLR01-01',
        projectId: 'PRJ-BLR-2024-01',
        name: 'Lakshmamma M.',
        age: 38,
        gender: 'Female',
        serviceReceived: 'Silk Jacquard Handloom Weaving Certificate',
        date: '2024-09-10',
      ),
      BeneficiaryModel(
        id: 'BEN-BLR01-02',
        projectId: 'PRJ-BLR-2024-01',
        name: 'Narasimha Murthy',
        age: 42,
        gender: 'Male',
        serviceReceived: 'Organic Dye Formulation & Quality Grader Badge',
        date: '2024-10-02',
      ),
      BeneficiaryModel(
        id: 'BEN-BLR01-03',
        projectId: 'PRJ-BLR-2024-01',
        name: 'Kenchappa R.',
        age: 45,
        gender: 'Male',
        serviceReceived: 'Cooperative Society Shareholder Enrollment',
        date: '2024-11-15',
      ),
      BeneficiaryModel(
        id: 'BEN-BLR01-04',
        projectId: 'PRJ-BLR-2024-01',
        name: 'Rathnamma K.',
        age: 34,
        gender: 'Female',
        serviceReceived: 'E-Commerce Marketplace Listing Training',
        date: '2025-01-20',
      ),
      BeneficiaryModel(
        id: 'BEN-BLR01-05',
        projectId: 'PRJ-BLR-2024-01',
        name: 'Manjunath S.',
        age: 28,
        gender: 'Male',
        serviceReceived: 'Micro-Credit Bank Account & Mudra Loan Sanction',
        date: '2025-03-12',
      ),

      // PRJ-LKO-2025-01
      BeneficiaryModel(
        id: 'BEN-LKO01-01',
        projectId: 'PRJ-LKO-2025-01',
        name: 'Kusum Lata',
        age: 36,
        gender: 'Female',
        serviceReceived: 'Commercial Apparel Pattern Cutting Course',
        date: '2025-06-14',
      ),
      BeneficiaryModel(
        id: 'BEN-LKO01-02',
        projectId: 'PRJ-LKO-2025-01',
        name: 'Raziya Bano',
        age: 32,
        gender: 'Female',
        serviceReceived: 'Chikan Hand Embroidery Master Artisan Badge',
        date: '2025-06-28',
      ),
      BeneficiaryModel(
        id: 'BEN-LKO01-03',
        projectId: 'PRJ-LKO-2025-01',
        name: 'Geeta Devi',
        age: 40,
        gender: 'Female',
        serviceReceived: 'Pickle & Fruit Preservation FSSAI Certificate',
        date: '2025-07-15',
      ),
      BeneficiaryModel(
        id: 'BEN-LKO01-04',
        projectId: 'PRJ-LKO-2025-01',
        name: 'Meena Prajapati',
        age: 29,
        gender: 'Female',
        serviceReceived: 'Self-Help Group Bookkeeping & Banking Unit',
        date: '2025-08-01',
      ),
      BeneficiaryModel(
        id: 'BEN-LKO01-05',
        projectId: 'PRJ-LKO-2025-01',
        name: 'Shabana Khatoon',
        age: 35,
        gender: 'Female',
        serviceReceived: 'Micro-Enterprise Sewing Machine Grant Receipt',
        date: '2025-08-22',
      ),

      // PRJ-JAI-2025-01
      BeneficiaryModel(
        id: 'BEN-JAI01-01',
        projectId: 'PRJ-JAI-2025-01',
        name: 'Ram Lal Meena',
        age: 67,
        gender: 'Male',
        serviceReceived: 'Right Eye Micro-Incision Cataract Surgery (MICS)',
        date: '2025-04-18',
      ),
      BeneficiaryModel(
        id: 'BEN-JAI01-02',
        projectId: 'PRJ-JAI-2025-01',
        name: 'Prem Kanwar',
        age: 71,
        gender: 'Female',
        serviceReceived: 'Bilateral Cataract Implantation & Post-op Kit',
        date: '2025-05-02',
      ),
      BeneficiaryModel(
        id: 'BEN-JAI01-03',
        projectId: 'PRJ-JAI-2025-01',
        name: 'Mohan Lal Gurjar',
        age: 63,
        gender: 'Male',
        serviceReceived: 'Diabetic Retinopathy Screening & High-Index Glasses',
        date: '2025-06-12',
      ),
      BeneficiaryModel(
        id: 'BEN-JAI01-04',
        projectId: 'PRJ-JAI-2025-01',
        name: 'Kesar Devi',
        age: 69,
        gender: 'Female',
        serviceReceived: 'Free Spectacles Prescription & Glaucoma Drops',
        date: '2025-07-05',
      ),
      BeneficiaryModel(
        id: 'BEN-JAI01-05',
        projectId: 'PRJ-JAI-2025-01',
        name: 'Chhitar Mal',
        age: 75,
        gender: 'Male',
        serviceReceived: 'Left Eye Foldable IOL Surgery & Followup Exam',
        date: '2025-08-14',
      ),
    ]);

    // Documents for all projects
    _documents.addAll([
      // PRJ-DEL-2025-01
      DocumentModel(
        id: 'DOC-DEL01-01',
        projectId: 'PRJ-DEL-2025-01',
        title: 'Form GFR 12-A Utilization Certificate (H1)',
        docType: 'Utilization Certificate',
        fileUrl: '/media/documents/uc_h1_2025.pdf',
        fileSize: '1.8 MB',
        uploadedAt: '2025-07-15',
        sha256Hash: computeSha256('SAMPLE_UTILIZATION_CERT_PRJ_DEL_01'),
      ),
      DocumentModel(
        id: 'DOC-DEL01-02',
        projectId: 'PRJ-DEL-2025-01',
        title: 'Tax Invoice - AssistTech Braille Units #8801',
        docType: 'Vendor Invoice',
        fileUrl: '/media/documents/inv_assisttech_8801.pdf',
        fileSize: '840 KB',
        uploadedAt: '2025-05-18',
        sha256Hash: computeSha256('SAMPLE_INVOICE_ASSIST_TECH_8801'),
      ),

      // PRJ-DEL-2025-02
      DocumentModel(
        id: 'DOC-DEL02-01',
        projectId: 'PRJ-DEL-2025-02',
        title: 'MoSJE Scheme Sanction Order #114-GER',
        docType: 'Sanction Order',
        fileUrl: '/media/documents/sanction_del02_114.pdf',
        fileSize: '2.1 MB',
        uploadedAt: '2025-06-20',
        sha256Hash: computeSha256('SANCTION_ORDER_PRJ_DEL_02'),
      ),
      DocumentModel(
        id: 'DOC-DEL02-02',
        projectId: 'PRJ-DEL-2025-02',
        title: 'Medical Devices Drug & Cosmetology Compliance Certificate',
        docType: 'Regulatory Compliance',
        fileUrl: '/media/documents/compliance_med_del02.pdf',
        fileSize: '1.2 MB',
        uploadedAt: '2025-07-05',
        sha256Hash: computeSha256('COMPLIANCE_MED_DEL_02'),
      ),

      // PRJ-MUM-2025-01
      DocumentModel(
        id: 'DOC-MUM01-01',
        projectId: 'PRJ-MUM-2025-01',
        title: 'NAPDDR Quarterly Utilization Certificate (Q2)',
        docType: 'Utilization Certificate',
        fileUrl: '/media/documents/uc_napddr_mum01.pdf',
        fileSize: '2.4 MB',
        uploadedAt: '2025-06-30',
        sha256Hash: computeSha256('UC_NAPDDR_MUM_01'),
      ),
      DocumentModel(
        id: 'DOC-MUM01-02',
        projectId: 'PRJ-MUM-2025-01',
        title: 'Scheduled Drugs Pharmacy Batch Ledger Audit',
        docType: 'Audit Report',
        fileUrl: '/media/documents/audit_pharma_mum01.pdf',
        fileSize: '1.5 MB',
        uploadedAt: '2025-07-20',
        sha256Hash: computeSha256('AUDIT_PHARMA_MUM_01'),
      ),

      // PRJ-BLR-2024-01
      DocumentModel(
        id: 'DOC-BLR01-01',
        projectId: 'PRJ-BLR-2024-01',
        title: 'Final Completion Audit & Form GFR 12-C',
        docType: 'Utilization Certificate',
        fileUrl: '/media/documents/final_uc_blr01.pdf',
        fileSize: '3.1 MB',
        uploadedAt: '2025-07-02',
        sha256Hash: computeSha256('FINAL_COMPLETION_UC_BLR_01'),
      ),
      DocumentModel(
        id: 'DOC-BLR01-02',
        projectId: 'PRJ-BLR-2024-01',
        title: 'Artisan Cooperative Registration Certificate #KA-BLR-882',
        docType: 'Registration Certificate',
        fileUrl: '/media/documents/coop_cert_blr01.pdf',
        fileSize: '950 KB',
        uploadedAt: '2024-11-20',
        sha256Hash: computeSha256('COOP_REG_CERT_BLR_01'),
      ),

      // PRJ-LKO-2025-01
      DocumentModel(
        id: 'DOC-LKO01-01',
        projectId: 'PRJ-LKO-2025-01',
        title: 'FSSAI Food Safety Hygiene Compliance Certificate',
        docType: 'Regulatory Compliance',
        fileUrl: '/media/documents/fssai_cert_lko01.pdf',
        fileSize: '1.1 MB',
        uploadedAt: '2025-07-10',
        sha256Hash: computeSha256('FSSAI_COMPLIANCE_LKO_01'),
      ),
      DocumentModel(
        id: 'DOC-LKO01-02',
        projectId: 'PRJ-LKO-2025-01',
        title: 'Machinery Procurement E-Tender Evaluation Report',
        docType: 'Procurement Audit',
        fileUrl: '/media/documents/etender_report_lko01.pdf',
        fileSize: '1.7 MB',
        uploadedAt: '2025-06-18',
        sha256Hash: computeSha256('ETENDER_REPORT_LKO_01'),
      ),

      // PRJ-JAI-2025-01
      DocumentModel(
        id: 'DOC-JAI01-01',
        projectId: 'PRJ-JAI-2025-01',
        title: 'Cataract Surgery Log & District CMO Clearance Certificate',
        docType: 'Clinical Clearance',
        fileUrl: '/media/documents/cmo_clearance_jai01.pdf',
        fileSize: '2.8 MB',
        uploadedAt: '2025-06-15',
        sha256Hash: computeSha256('CMO_CLEARANCE_JAI_01'),
      ),
      DocumentModel(
        id: 'DOC-JAI01-02',
        projectId: 'PRJ-JAI-2025-01',
        title: 'Beneficiary Post-Op Visual Acuity Assessment Ledger',
        docType: 'Medical Records',
        fileUrl: '/media/documents/postop_acuity_jai01.pdf',
        fileSize: '1.9 MB',
        uploadedAt: '2025-08-10',
        sha256Hash: computeSha256('POSTOP_ACUITY_JAI_01'),
      ),
    ]);

    // Cameras for all projects (YOLOv11 streams)
    _cameras.addAll([
      // PRJ-DEL-2025-01
      CameraModel(
        id: 'CAM-DEL01-01',
        projectId: 'PRJ-DEL-2025-01',
        name: 'Classroom 101 - Main Training Lab',
        streamUrl: 'resources/simulated_classroom_cctv.mp4',
        status: 'Online',
        lastHeadcount: 15,
        expectedHeadcount: 35,
        riskScore: 78.5,
      ),
      CameraModel(
        id: 'CAM-DEL01-02',
        projectId: 'PRJ-DEL-2025-01',
        name: 'Entrance Foyer & Attendance Kiosk',
        streamUrl: 'resources/entrance_kiosk_cctv.mp4',
        status: 'Online',
        lastHeadcount: 8,
        expectedHeadcount: 10,
        riskScore: 14.0,
      ),

      // PRJ-DEL-2025-02
      CameraModel(
        id: 'CAM-DEL02-01',
        projectId: 'PRJ-DEL-2025-02',
        name: 'Senior Activity Hall & Daycare Lounge',
        streamUrl: 'resources/simulated_classroom_cctv.mp4',
        status: 'Online',
        lastHeadcount: 22,
        expectedHeadcount: 25,
        riskScore: 12.0,
      ),
      CameraModel(
        id: 'CAM-DEL02-02',
        projectId: 'PRJ-DEL-2025-02',
        name: 'Physiotherapy Ward & Ramp Gate',
        streamUrl: 'resources/entrance_kiosk_cctv.mp4',
        status: 'Online',
        lastHeadcount: 14,
        expectedHeadcount: 15,
        riskScore: 8.5,
      ),

      // PRJ-MUM-2025-01
      CameraModel(
        id: 'CAM-MUM01-01',
        projectId: 'PRJ-MUM-2025-01',
        name: 'Detox Ward Dayroom & Group Therapy Hall',
        streamUrl: 'resources/simulated_classroom_cctv.mp4',
        status: 'Online',
        lastHeadcount: 28,
        expectedHeadcount: 40,
        riskScore: 68.0,
      ),
      CameraModel(
        id: 'CAM-MUM01-02',
        projectId: 'PRJ-MUM-2025-01',
        name: 'Dispensary Entry & Biometric Kiosk',
        streamUrl: 'resources/entrance_kiosk_cctv.mp4',
        status: 'Online',
        lastHeadcount: 5,
        expectedHeadcount: 6,
        riskScore: 10.0,
      ),

      // PRJ-BLR-2024-01
      CameraModel(
        id: 'CAM-BLR01-01',
        projectId: 'PRJ-BLR-2024-01',
        name: 'Central Handloom Weaving Shed',
        streamUrl: 'resources/simulated_classroom_cctv.mp4',
        status: 'Online',
        lastHeadcount: 30,
        expectedHeadcount: 30,
        riskScore: 0.0,
      ),
      CameraModel(
        id: 'CAM-BLR01-02',
        projectId: 'PRJ-BLR-2024-01',
        name: 'Yarn Storage & Packing Hall',
        streamUrl: 'resources/entrance_kiosk_cctv.mp4',
        status: 'Online',
        lastHeadcount: 12,
        expectedHeadcount: 12,
        riskScore: 0.0,
      ),

      // PRJ-LKO-2025-01
      CameraModel(
        id: 'CAM-LKO01-01',
        projectId: 'PRJ-LKO-2025-01',
        name: 'Industrial Sewing Workshop Room A',
        streamUrl: 'resources/simulated_classroom_cctv.mp4',
        status: 'Online',
        lastHeadcount: 18,
        expectedHeadcount: 25,
        riskScore: 36.0,
      ),
      CameraModel(
        id: 'CAM-LKO01-02',
        projectId: 'PRJ-LKO-2025-01',
        name: 'Food Processing & Packaging Kitchen',
        streamUrl: 'resources/entrance_kiosk_cctv.mp4',
        status: 'Online',
        lastHeadcount: 10,
        expectedHeadcount: 12,
        riskScore: 15.0,
      ),

      // PRJ-JAI-2025-01
      CameraModel(
        id: 'CAM-JAI01-01',
        projectId: 'PRJ-JAI-2025-01',
        name: 'Ophthalmic Screening Hall',
        streamUrl: 'resources/simulated_classroom_cctv.mp4',
        status: 'Online',
        lastHeadcount: 32,
        expectedHeadcount: 35,
        riskScore: 16.0,
      ),
      CameraModel(
        id: 'CAM-JAI01-02',
        projectId: 'PRJ-JAI-2025-01',
        name: 'Pre-op Ward & Spectacle Dispensary',
        streamUrl: 'resources/entrance_kiosk_cctv.mp4',
        status: 'Online',
        lastHeadcount: 15,
        expectedHeadcount: 18,
        riskScore: 18.0,
      ),
    ]);

    // Alerts for all projects
    _alerts.addAll([
      // PRJ-DEL-2025-01
      AlertModel(
        id: 'ALT-DEL01-01',
        projectId: 'PRJ-DEL-2025-01',
        projectName: 'PM-DAKSH Divyangjan Skill Center',
        severity: 'Critical',
        reason: 'Automated CCTV Headcount Alert: Detected 15 vs 35 expected capacity (Risk: 78.5%)',
        status: 'Open',
        createdAt: '2026-09-22 10:14:00',
      ),
      AlertModel(
        id: 'ALT-DEL01-02',
        projectId: 'PRJ-DEL-2025-01',
        projectName: 'PM-DAKSH Divyangjan Skill Center',
        severity: 'Elevated',
        reason: 'Vendor invoice mismatch flagged on TXN-DEL-8804 (broadband line items)',
        status: 'Open',
        createdAt: '2026-09-20 16:45:00',
      ),

      // PRJ-DEL-2025-02
      AlertModel(
        id: 'ALT-DEL02-01',
        projectId: 'PRJ-DEL-2025-02',
        projectName: 'Senior Citizens Daycare & Medical Wing',
        severity: 'Normal',
        reason: 'Routine quarterly medical equipment calibration due within 14 days',
        status: 'Open',
        createdAt: '2026-09-21 09:30:00',
      ),

      // PRJ-MUM-2025-01
      AlertModel(
        id: 'ALT-MUM01-01',
        projectId: 'PRJ-MUM-2025-01',
        projectName: 'De-addiction & Psychosocial Rehab Center',
        severity: 'Critical',
        reason: 'CCTV Discrepancy & Pharmacy Ledger mismatch: Missing narcotic register entry',
        status: 'Open',
        createdAt: '2026-09-18 14:10:00',
      ),
      AlertModel(
        id: 'ALT-MUM01-02',
        projectId: 'PRJ-MUM-2025-01',
        projectName: 'De-addiction & Psychosocial Rehab Center',
        severity: 'Elevated',
        reason: 'Automated CCTV Headcount Alert: Detected 28 vs 40 expected bed occupancy (Risk: 68.0%)',
        status: 'Open',
        createdAt: '2026-09-19 11:05:00',
      ),

      // PRJ-BLR-2024-01
      AlertModel(
        id: 'ALT-BLR01-01',
        projectId: 'PRJ-BLR-2024-01',
        projectName: 'Rural SC/ST Artisan Livelihood Program',
        severity: 'Normal',
        reason: 'Final audit clearance pending ministerial sign-off (Project completed 100%)',
        status: 'Open',
        createdAt: '2026-09-15 15:20:00',
      ),

      // PRJ-LKO-2025-01
      AlertModel(
        id: 'ALT-LKO01-01',
        projectId: 'PRJ-LKO-2025-01',
        projectName: 'Destitute Women Micro-Enterprise Hub',
        severity: 'Elevated',
        reason: 'Attendance lag: 18/25 trainees recorded on Room A CCTV during morning shift',
        status: 'Open',
        createdAt: '2026-09-23 11:45:00',
      ),

      // PRJ-JAI-2025-01
      AlertModel(
        id: 'ALT-JAI01-01',
        projectId: 'PRJ-JAI-2025-01',
        projectName: 'Vision Restorative Eyecare Mission',
        severity: 'Normal',
        reason: 'Batch renewal for consumable intraocular lenses required before Q4 camp',
        status: 'Open',
        createdAt: '2026-09-17 13:10:00',
      ),
    ]);

    // Inspections for all projects
    final inspHash1 = computeSha256('INSP-MOSJE-2026-001:VERIFIED:AKSHAYA');
    final inspHash2 = computeSha256('INSP-MOSJE-2026-002:REQUIRES_ACTION:MUMBAI');
    final inspHash3 = computeSha256('INSP-MOSJE-2026-003:ASSIGNED:BANGALORE');
    final inspHash4 = computeSha256('INSP-MOSJE-2026-004:VERIFIED:LUCKNOW');
    final inspHash5 = computeSha256('INSP-MOSJE-2026-005:VERIFIED:JAIPUR');
    final inspHash6 = computeSha256('INSP-MOSJE-2026-006:VERIFIED:DELHI_SENIORS');

    _inspections.addAll([
      InspectionModel(
        inspectionId: 'INSP-MOSJE-2026-001',
        orgId: 'NGO-DEL-01',
        orgName: 'Akshaya Vidya Foundation',
        projectId: 'PRJ-DEL-2025-01',
        projectName: 'PM-DAKSH Divyangjan Skill Center',
        assignedInspector: 'Inspector Rajesh V.',
        status: 'Reviewed',
        overallResult: 'Verified',
        governmentReview: 'Verified',
        assignedDate: '2026-09-10',
        submittedDate: '2026-09-15',
        reason: 'Unannounced AI Discrepancy Dispatch (Classroom Attendance Low)',
        latitude: 28.5921,
        longitude: 77.0460,
        capturedTimestamp: '2026-09-15 11:24:18',
        checklistResults: {
          'Infrastructure & Classrooms': 'Pass',
          'Biometric & Headcount Validation': 'Pass',
          'Sanitation & Barrier-Free Access': 'Pass',
          'Beneficiary Stipend Records': 'Pass',
          'Faculty Attendance & Credentials': 'Pass',
        },
        photoWatermarkData: {
          'camera_model': 'GovAudit-Handheld-T4',
          'latitude': 28.5921,
          'longitude': 77.0460,
          'altitude_m': 218.4,
          'timestamp': '2026-09-15T11:24:18Z',
          'device_imei_hash': '8f9024a49c66911c42e',
        },
        photoUrl: 'assets/dwarka_center.jpg',
        observations: 'Center found operating with adequate hardware. Low headcount was temporary due to monsoon morning transport delays. Trainees verified via biometric register.',
        sha256Hash: inspHash1,
      ),
      InspectionModel(
        inspectionId: 'INSP-MOSJE-2026-002',
        orgId: 'NGO-MUM-02',
        orgName: 'Samarpan Seva Samiti',
        projectId: 'PRJ-MUM-2025-01',
        projectName: 'De-addiction & Psychosocial Rehab Center',
        assignedInspector: 'Inspector Anita Desai',
        status: 'Submitted',
        overallResult: 'Requires Further Action',
        governmentReview: 'Requires Further Action',
        assignedDate: '2026-09-14',
        submittedDate: '2026-09-18',
        reason: 'Routine Annual Mandatory Audit',
        latitude: 19.0596,
        longitude: 72.8406,
        capturedTimestamp: '2026-09-18 14:10:02',
        checklistResults: {
          'Ward Cleanliness': 'Pass',
          'Medical Records & Pharmacy': 'Fail',
          'Safety & Fire Norms': 'Pass',
          'Patient Attendance Register': 'Fail',
        },
        photoWatermarkData: {
          'camera_model': 'GovAudit-Handheld-T4',
          'latitude': 19.0596,
          'longitude': 72.8406,
          'altitude_m': 12.0,
          'timestamp': '2026-09-18T14:10:02Z',
        },
        photoUrl: 'assets/mumbai_center.jpg',
        observations: 'Medicine stock registers had multiple missing batch entries. Direct explanation requested from Head of Pharmacy.',
        sha256Hash: inspHash2,
      ),
      InspectionModel(
        inspectionId: 'INSP-MOSJE-2026-003',
        orgId: 'NGO-BLR-03',
        orgName: 'Pragati Gramin Vikas Trust',
        projectId: 'PRJ-BLR-2024-01',
        projectName: 'Rural SC/ST Artisan Livelihood Program',
        assignedInspector: 'Inspector Rajesh V.',
        status: 'Reviewed',
        overallResult: 'Verified',
        governmentReview: 'Verified',
        assignedDate: '2026-08-20',
        submittedDate: '2026-08-25',
        reason: 'Milestone Progress & Final Utilization Verification',
        latitude: 12.9784,
        longitude: 77.6408,
        capturedTimestamp: '2026-08-25 15:40:00',
        checklistResults: {
          'Artisan Looms Operating': 'Pass',
          'Yarn Inventory Reconciliation': 'Pass',
          'Cooperative Bank Passbooks': 'Pass',
          'Beneficiary Sign-off': 'Pass',
        },
        photoWatermarkData: {
          'camera_model': 'GovAudit-Handheld-T4',
          'latitude': 12.9784,
          'longitude': 77.6408,
          'timestamp': '2026-08-25T15:40:00Z',
        },
        observations: '120 rural artisan families actively weaving. High-quality silk fabrics displayed. All books reconciled.',
        sha256Hash: inspHash3,
      ),
      InspectionModel(
        inspectionId: 'INSP-MOSJE-2026-004',
        orgId: 'NGO-LKO-04',
        orgName: 'Chetna Mahila Kalyan Parishad',
        projectId: 'PRJ-LKO-2025-01',
        projectName: 'Destitute Women Micro-Enterprise Hub',
        assignedInspector: 'Inspector Sunita Verma',
        status: 'Reviewed',
        overallResult: 'Verified',
        governmentReview: 'Verified',
        assignedDate: '2026-09-01',
        submittedDate: '2026-09-06',
        reason: 'Mid-term Scheme Verification Audit',
        latitude: 26.8467,
        longitude: 80.9462,
        capturedTimestamp: '2026-09-06 12:15:30',
        checklistResults: {
          'Apparel Workshop Safety': 'Pass',
          'Food Safety FSSAI Hygiene': 'Pass',
          'Trainee Attendance': 'Pass',
          'Raw Material Stock': 'Pass',
        },
        observations: 'All 20 sewing machines operational. Packaging facility complies with hygiene standards.',
        sha256Hash: inspHash4,
      ),
      InspectionModel(
        inspectionId: 'INSP-MOSJE-2026-005',
        orgId: 'NGO-JAI-05',
        orgName: 'Arogya Drishti Mission',
        projectId: 'PRJ-JAI-2025-01',
        projectName: 'Vision Restorative Eyecare Mission',
        assignedInspector: 'Inspector Vikram Rathore',
        status: 'Reviewed',
        overallResult: 'Verified',
        governmentReview: 'Verified',
        assignedDate: '2026-09-08',
        submittedDate: '2026-09-12',
        reason: 'Surgical Camp Sterility & Beneficiary Audit',
        latitude: 26.9124,
        longitude: 75.7873,
        capturedTimestamp: '2026-09-12 10:45:12',
        checklistResults: {
          'OT Sterilization Standards': 'Pass',
          'IOL Batch Number Tracing': 'Pass',
          'Post-op Followup Register': 'Pass',
          'Zero-Cost Verification': 'Pass',
        },
        observations: 'Cataract surgeries verified without any patient charges. Followup visual acuity exceeds 6/12 in 94% cases.',
        sha256Hash: inspHash5,
      ),
      InspectionModel(
        inspectionId: 'INSP-MOSJE-2026-006',
        orgId: 'NGO-DEL-01',
        orgName: 'Akshaya Vidya Foundation',
        projectId: 'PRJ-DEL-2025-02',
        projectName: 'Senior Citizens Daycare & Medical Wing',
        assignedInspector: 'Inspector Rajesh V.',
        status: 'Reviewed',
        overallResult: 'Verified',
        governmentReview: 'Verified',
        assignedDate: '2026-09-16',
        submittedDate: '2026-09-20',
        reason: 'Senior Welfare Compliance Audit',
        latitude: 28.5921,
        longitude: 77.0460,
        capturedTimestamp: '2026-09-20 14:00:00',
        checklistResults: {
          'Barrier-Free Access & Ramps': 'Pass',
          'Geriatric Medical Supervision': 'Pass',
          'Nutritional Food Hygiene': 'Pass',
          'Elderly Feedback Interviews': 'Pass',
        },
        observations: 'Daycare facility exemplary in barrier-free access. Senior citizens gave positive feedback regarding doctor visits.',
        sha256Hash: inspHash6,
      ),
    ]);

    // Progress Reports for all projects
    _progressReports.addAll([
      // PRJ-DEL-2025-01
      ProgressReportModel(
        id: 'REP-DEL01-01',
        projectId: 'PRJ-DEL-2025-01',
        projectName: 'PM-DAKSH Divyangjan Skill Center',
        progressPct: 78.0,
        beneficiariesServed: 142,
        notes: 'All 5 assistive computer modules completed. 28 candidates already placed in banking back-office apprenticeships.',
        submittedAt: '2026-09-14 18:22:00',
      ),
      ProgressReportModel(
        id: 'REP-DEL01-02',
        projectId: 'PRJ-DEL-2025-01',
        projectName: 'PM-DAKSH Divyangjan Skill Center',
        progressPct: 50.0,
        beneficiariesServed: 105,
        notes: 'Mid-term assessment completed. Braille keyboards and optical scanners installed in Lab 2.',
        submittedAt: '2025-07-28 14:10:00',
      ),

      // PRJ-DEL-2025-02
      ProgressReportModel(
        id: 'REP-DEL02-01',
        projectId: 'PRJ-DEL-2025-02',
        projectName: 'Senior Citizens Daycare & Medical Wing',
        progressPct: 65.0,
        beneficiariesServed: 84,
        notes: 'Daily attendance regularized with 84 registered seniors. Physiotherapy ward operating at full capacity.',
        submittedAt: '2026-09-10 16:30:00',
      ),

      // PRJ-MUM-2025-01
      ProgressReportModel(
        id: 'REP-MUM01-01',
        projectId: 'PRJ-MUM-2025-01',
        projectName: 'De-addiction & Psychosocial Rehab Center',
        progressPct: 88.0,
        beneficiariesServed: 192,
        notes: '192 patients treated under inpatient detox protocols. Community relapse prevention groups established across Bandra.',
        submittedAt: '2026-09-12 11:45:00',
      ),

      // PRJ-BLR-2024-01
      ProgressReportModel(
        id: 'REP-BLR01-01',
        projectId: 'PRJ-BLR-2024-01',
        projectName: 'Rural SC/ST Artisan Livelihood Program',
        progressPct: 100.0,
        beneficiariesServed: 120,
        notes: 'Project successfully concluded. 100% target achieved with registered cooperative marketing directly to e-commerce stores.',
        submittedAt: '2025-06-25 17:00:00',
      ),

      // PRJ-LKO-2025-01
      ProgressReportModel(
        id: 'REP-LKO01-01',
        projectId: 'PRJ-LKO-2025-01',
        projectName: 'Destitute Women Micro-Enterprise Hub',
        progressPct: 60.0,
        beneficiariesServed: 98,
        notes: 'Apparel stitching division completed first wholesale uniform contract. Food processing unit cleared FSSAI inspections.',
        submittedAt: '2026-09-08 15:10:00',
      ),

      // PRJ-JAI-2025-01
      ProgressReportModel(
        id: 'REP-JAI01-01',
        projectId: 'PRJ-JAI-2025-01',
        projectName: 'Vision Restorative Eyecare Mission',
        progressPct: 74.0,
        beneficiariesServed: 485,
        notes: '485 elderly patients screened, 210 cataract surgeries performed with foldable IOLs, zero infection rate reported.',
        submittedAt: '2026-09-15 12:20:00',
      ),
    ]);

    // Issue Reports
    _issueReports.addAll([
      IssueReportModel(
        id: 'ISS-001',
        orgId: 'NGO-DEL-01',
        orgName: 'Akshaya Vidya Foundation',
        subject: 'Delay in Q3 PFMS installment disbursement',
        description: 'Our second installment request submitted on 15 Aug remains in pending queue. Need urgent clearance for assistive equipment invoice.',
        priority: 'High',
        status: 'In Review',
        createdAt: '2026-09-20 14:30:00',
      ),
      IssueReportModel(
        id: 'ISS-002',
        orgId: 'NGO-DEL-01',
        orgName: 'Akshaya Vidya Foundation',
        subject: 'CCTV IP Stream configuration assistance requested',
        description: 'Classroom 101 optical fiber connection experienced bandwidth drops during heavy rain.',
        priority: 'Medium',
        status: 'Resolved',
        createdAt: '2026-09-12 11:00:00',
      ),
    ]);
  }
}
