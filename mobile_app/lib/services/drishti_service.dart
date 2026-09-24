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

    // Fundings for PRJ-DEL-2025-01
    _fundings.addAll([
      FundingModel(
        id: 'FND-001',
        projectId: 'PRJ-DEL-2025-01',
        source: 'MoSJE Central Scheme Grant',
        stage: 'Sanctioned',
        amount: 4500000.0,
        date: '2025-04-05',
        purpose: 'Annual operating and instructor grant under PM-DAKSH',
        reference: 'SAN-MOSJE-2025-081',
      ),
      FundingModel(
        id: 'FND-002',
        projectId: 'PRJ-DEL-2025-01',
        source: 'MoSJE First Tranche Release',
        stage: 'Released',
        amount: 3200000.0,
        date: '2025-04-20',
        purpose: 'Q1-Q3 installment disbursement',
        reference: 'REL-PFMS-99210',
      ),
    ]);

    // Expenses for PRJ-DEL-2025-01
    _expenses.addAll([
      ExpenseModel(
        txnId: 'TXN-DEL-8801',
        projectId: 'PRJ-DEL-2025-01',
        purpose: 'Procurement of 25 Braille Displays & Screen Readers',
        amount: 625000.0,
        vendor: 'AssistTech India Pvt Ltd',
        date: '2025-05-12',
        status: 'Verified',
      ),
      ExpenseModel(
        txnId: 'TXN-DEL-8802',
        projectId: 'PRJ-DEL-2025-01',
        purpose: 'Trainer Honorarium & Pedagogical Materials',
        amount: 420000.0,
        vendor: 'Faculty Welfare Consortium',
        date: '2025-06-28',
        status: 'Verified',
      ),
      ExpenseModel(
        txnId: 'TXN-DEL-8803',
        projectId: 'PRJ-DEL-2025-01',
        purpose: 'Nutritional Stipend Disbursement for Trainees',
        amount: 315000.0,
        vendor: 'Direct Beneficiary DBT Account',
        date: '2025-07-30',
        status: 'Verified',
      ),
      ExpenseModel(
        txnId: 'TXN-DEL-8804',
        projectId: 'PRJ-DEL-2025-01',
        purpose: 'CCTV Infrastructure Upgrades & Optical Broadband',
        amount: 180000.0,
        vendor: 'SecureNet Telecom Delhi',
        date: '2025-08-14',
        status: 'Pending',
      ),
    ]);

    // Beneficiaries
    _beneficiaries.addAll([
      BeneficiaryModel(
        id: 'BEN-001',
        projectId: 'PRJ-DEL-2025-01',
        name: 'Aarav Sharma',
        age: 22,
        gender: 'Male',
        serviceReceived: 'Assistive Computer Course Certificate',
        date: '2025-07-10',
      ),
      BeneficiaryModel(
        id: 'BEN-002',
        projectId: 'PRJ-DEL-2025-01',
        name: 'Pooja Kumari',
        age: 24,
        gender: 'Female',
        serviceReceived: 'Data Entry & Office Operations Module',
        date: '2025-07-15',
      ),
      BeneficiaryModel(
        id: 'BEN-003',
        projectId: 'PRJ-DEL-2025-01',
        name: 'Mohammed Farooq',
        age: 21,
        gender: 'Male',
        serviceReceived: 'Audio Editing & Screen Reader Tools',
        date: '2025-08-02',
      ),
      BeneficiaryModel(
        id: 'BEN-004',
        projectId: 'PRJ-DEL-2025-01',
        name: 'Sunita Verma',
        age: 27,
        gender: 'Female',
        serviceReceived: 'Financial Literacy & Typing Certification',
        date: '2025-08-20',
      ),
      BeneficiaryModel(
        id: 'BEN-005',
        projectId: 'PRJ-DEL-2025-01',
        name: 'Rohan Patel',
        age: 19,
        gender: 'Male',
        serviceReceived: 'Call Center Operations Skill Badge',
        date: '2025-09-05',
      ),
    ]);

    // Documents
    _documents.addAll([
      DocumentModel(
        id: 'DOC-001',
        projectId: 'PRJ-DEL-2025-01',
        title: 'Form GFR 12-A Utilization Certificate (H1)',
        docType: 'Utilization Certificate',
        fileUrl: '/media/documents/uc_h1_2025.pdf',
        fileSize: '1.8 MB',
        uploadedAt: '2025-07-15',
        sha256Hash: computeSha256('SAMPLE_UTILIZATION_CERT_PRJ_DEL_01'),
      ),
      DocumentModel(
        id: 'DOC-002',
        projectId: 'PRJ-DEL-2025-01',
        title: 'Tax Invoice - AssistTech Braille Units #8801',
        docType: 'Vendor Invoice',
        fileUrl: '/media/documents/inv_assisttech_8801.pdf',
        fileSize: '840 KB',
        uploadedAt: '2025-05-18',
        sha256Hash: computeSha256('SAMPLE_INVOICE_ASSIST_TECH_8801'),
      ),
    ]);

    // Cameras
    _cameras.addAll([
      CameraModel(
        id: 'CAM-001',
        projectId: 'PRJ-DEL-2025-01',
        name: 'Classroom 101 - Main Training Lab',
        streamUrl: 'resources/simulated_classroom_cctv.mp4',
        status: 'Online',
        lastHeadcount: 12,
        expectedHeadcount: 35,
        riskScore: 78.5,
      ),
      CameraModel(
        id: 'CAM-002',
        projectId: 'PRJ-DEL-2025-01',
        name: 'Entrance Foyer & Attendance Kiosk',
        streamUrl: 'resources/entrance_kiosk_cctv.mp4',
        status: 'Online',
        lastHeadcount: 8,
        expectedHeadcount: 10,
        riskScore: 14.0,
      ),
    ]);

    // Alerts
    _alerts.addAll([
      AlertModel(
        id: 'ALT-001',
        projectId: 'PRJ-DEL-2025-01',
        projectName: 'PM-DAKSH Divyangjan Skill Center',
        severity: 'Critical',
        reason: 'Automated CCTV Headcount Alert: Detected 12 vs 35 expected capacity (Risk: 78.5%)',
        status: 'Open',
        createdAt: '2026-09-22 10:14:00',
      ),
      AlertModel(
        id: 'ALT-002',
        projectId: 'PRJ-DEL-2025-01',
        projectName: 'PM-DAKSH Divyangjan Skill Center',
        severity: 'Elevated',
        reason: 'Vendor invoice mismatch flagged on TXN-DEL-8804 (broadband line items)',
        status: 'Open',
        createdAt: '2026-09-20 16:45:00',
      ),
      AlertModel(
        id: 'ALT-003',
        projectId: 'PRJ-MUM-2025-01',
        projectName: 'De-addiction & Psychosocial Rehab Center',
        severity: 'Elevated',
        reason: 'Pharmacy batch register discrepancy flagged during internal quarterly reconciliation',
        status: 'Open',
        createdAt: '2026-09-18 14:10:00',
      ),
    ]);

    // Inspections
    final inspHash1 = computeSha256('INSP-MOSJE-2026-001:VERIFIED:AKSHAYA');
    final inspHash2 = computeSha256('INSP-MOSJE-2026-002:REQUIRES_ACTION:MUMBAI');

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
          'Biometric & Headcount Validation': 'Fail',
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
        status: 'Assigned',
        overallResult: '—',
        governmentReview: 'Pending',
        assignedDate: '2026-09-22',
        submittedDate: null,
        reason: 'Milestone Progress & Final Utilization Verification',
        latitude: 12.9784,
        longitude: 77.6408,
      ),
    ]);

    // Audit Logs
    _auditLogs.addAll([
      AuditLogModel(
        user: 'Admin Sharma',
        role: 'Admin',
        action: 'SANCTION_ISSUED',
        entity: 'Project PRJ-DEL-2025-01 (₹45,00,000)',
        timestamp: '2026-09-23 15:40:12',
      ),
      AuditLogModel(
        user: 'System (AI Stream Processor)',
        role: 'Admin',
        action: 'CRITICAL_HEADCOUNT_ALERT',
        entity: 'Akshaya Vidya Foundation (12/35 present)',
        timestamp: '2026-09-22 10:14:00',
      ),
      AuditLogModel(
        user: 'Director MoSJE',
        role: 'Admin',
        action: 'INSPECTION_DISPATCHED',
        entity: 'INSP-MOSJE-2026-003 to Inspector Rajesh V.',
        timestamp: '2026-09-22 09:30:00',
      ),
      AuditLogModel(
        user: 'Inspector Rajesh V.',
        role: 'Inspector',
        action: 'GEOLOCK_VERIFIED',
        entity: 'GeoFence GPS match at 28.5921, 77.0460',
        timestamp: '2026-09-15 11:20:00',
      ),
      AuditLogModel(
        user: 'Inspector Rajesh V.',
        role: 'Inspector',
        action: 'INSPECTION_SUBMITTED',
        entity: 'INSP-MOSJE-2026-001 (SHA-256: ${inspHash1.substring(0, 16)}...)',
        timestamp: '2026-09-15 11:45:00',
      ),
      AuditLogModel(
        user: 'Admin Sharma',
        role: 'Admin',
        action: 'GOVERNMENT_REVIEW_VERIFIED',
        entity: 'INSP-MOSJE-2026-001 marked Verified',
        timestamp: '2026-09-16 14:10:00',
      ),
      AuditLogModel(
        user: 'Akshaya Vidya Foundation',
        role: 'NGO Officer',
        action: 'PROGRESS_REPORT_SUBMITTED',
        entity: 'Q2 Progress 78% with trainee placement records',
        timestamp: '2026-09-14 18:22:00',
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

    // Progress Reports
    _progressReports.addAll([
      ProgressReportModel(
        id: 'REP-001',
        projectId: 'PRJ-DEL-2025-01',
        projectName: 'PM-DAKSH Divyangjan Skill Center',
        progressPct: 78.0,
        beneficiariesServed: 142,
        notes: 'All 5 assistive computer modules completed. 28 candidates already placed in banking back-office apprenticeships.',
        submittedAt: '2026-09-14 18:22:00',
      ),
    ]);
  }
}
