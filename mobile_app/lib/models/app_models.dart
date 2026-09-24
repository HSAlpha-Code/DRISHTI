class OrganizationModel {
  final String id;
  final String name;
  final String registrationId;
  final String sector;
  final String city;
  final String state;
  final String fullAddress;
  final String contactEmail;
  final String contactPhone;
  final String verificationStatus; // Verified, Pending, Under Review
  final List<String> servicesProvided;
  final List<String> scopeAndFacilities;
  final double latitude;
  final double longitude;

  OrganizationModel({
    required this.id,
    required this.name,
    required this.registrationId,
    required this.sector,
    required this.city,
    required this.state,
    required this.fullAddress,
    required this.contactEmail,
    required this.contactPhone,
    required this.verificationStatus,
    required this.servicesProvided,
    required this.scopeAndFacilities,
    required this.latitude,
    required this.longitude,
  });

  OrganizationModel copyWith({
    String? verificationStatus,
  }) {
    return OrganizationModel(
      id: id,
      name: name,
      registrationId: registrationId,
      sector: sector,
      city: city,
      state: state,
      fullAddress: fullAddress,
      contactEmail: contactEmail,
      contactPhone: contactPhone,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      servicesProvided: servicesProvided,
      scopeAndFacilities: scopeAndFacilities,
      latitude: latitude,
      longitude: longitude,
    );
  }
}

class ProjectModel {
  final String id;
  final String orgId;
  final String orgName;
  final String name;
  final String category;
  final String status; // Active, Completed, Suspended
  final String startDate;
  final String endDate;
  final String description;
  final double sanctionedAmount;
  final double releasedAmount;
  final double spentAmount;
  final int beneficiariesTarget;
  final int beneficiariesRegistered;
  final double progressPct;

  ProjectModel({
    required this.id,
    required this.orgId,
    required this.orgName,
    required this.name,
    required this.category,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.description,
    required this.sanctionedAmount,
    required this.releasedAmount,
    required this.spentAmount,
    required this.beneficiariesTarget,
    required this.beneficiariesRegistered,
    required this.progressPct,
  });

  double get remainingAmount => releasedAmount - spentAmount > 0 ? releasedAmount - spentAmount : 0.0;
  double get utilizationPct => releasedAmount > 0 ? (spentAmount / releasedAmount) * 100 : 0.0;

  ProjectModel copyWith({
    double? sanctionedAmount,
    double? releasedAmount,
    double? spentAmount,
    int? beneficiariesRegistered,
    double? progressPct,
    String? status,
  }) {
    return ProjectModel(
      id: id,
      orgId: orgId,
      orgName: orgName,
      name: name,
      category: category,
      status: status ?? this.status,
      startDate: startDate,
      endDate: endDate,
      description: description,
      sanctionedAmount: sanctionedAmount ?? this.sanctionedAmount,
      releasedAmount: releasedAmount ?? this.releasedAmount,
      spentAmount: spentAmount ?? this.spentAmount,
      beneficiariesTarget: beneficiariesTarget,
      beneficiariesRegistered: beneficiariesRegistered ?? this.beneficiariesRegistered,
      progressPct: progressPct ?? this.progressPct,
    );
  }
}

class FundingModel {
  final String id;
  final String projectId;
  final String source;
  final String stage; // Sanctioned, Released
  final double amount;
  final String date;
  final String purpose;
  final String reference;

  FundingModel({
    required this.id,
    required this.projectId,
    required this.source,
    required this.stage,
    required this.amount,
    required this.date,
    required this.purpose,
    required this.reference,
  });
}

class ExpenseModel {
  final String txnId;
  final String projectId;
  final String purpose;
  final double amount;
  final String vendor;
  final String date;
  final String status; // Verified, Pending

  ExpenseModel({
    required this.txnId,
    required this.projectId,
    required this.purpose,
    required this.amount,
    required this.vendor,
    required this.date,
    required this.status,
  });
}

class BeneficiaryModel {
  final String id;
  final String projectId;
  final String name;
  final int age;
  final String gender;
  final String serviceReceived;
  final String date;

  BeneficiaryModel({
    required this.id,
    required this.projectId,
    required this.name,
    required this.age,
    required this.gender,
    required this.serviceReceived,
    required this.date,
  });
}

class DocumentModel {
  final String id;
  final String projectId;
  final String title;
  final String docType;
  final String fileUrl;
  final String fileSize;
  final String uploadedAt;
  final String sha256Hash;

  DocumentModel({
    required this.id,
    required this.projectId,
    required this.title,
    required this.docType,
    required this.fileUrl,
    required this.fileSize,
    required this.uploadedAt,
    required this.sha256Hash,
  });
}

class CameraModel {
  final String id;
  final String projectId;
  final String name;
  final String streamUrl;
  final String status; // Online, Offline
  final int lastHeadcount;
  final int expectedHeadcount;
  final double riskScore;

  CameraModel({
    required this.id,
    required this.projectId,
    required this.name,
    required this.streamUrl,
    required this.status,
    required this.lastHeadcount,
    required this.expectedHeadcount,
    required this.riskScore,
  });
}

class AlertModel {
  final String id;
  final String projectId;
  final String projectName;
  final String severity; // Critical, Elevated, Normal
  final String reason;
  final String status; // Open, Resolved
  final String createdAt;

  AlertModel({
    required this.id,
    required this.projectId,
    required this.projectName,
    required this.severity,
    required this.reason,
    required this.status,
    required this.createdAt,
  });
}

class InspectionModel {
  final String inspectionId;
  final String orgId;
  final String orgName;
  final String projectId;
  final String projectName;
  final String assignedInspector;
  final String status; // Assigned, In Progress, Submitted, Reviewed
  final String overallResult; // Verified, Partially Verified, Requires Further Action, —
  final String governmentReview; // Pending, Verified, Requires Further Action
  final String assignedDate;
  final String? submittedDate;
  final String reason;
  final double? latitude;
  final double? longitude;
  final String? capturedTimestamp;
  final Map<String, String> checklistResults;
  final Map<String, dynamic> photoWatermarkData;
  final String? photoUrl;
  final String observations;
  final String? sha256Hash;

  InspectionModel({
    required this.inspectionId,
    required this.orgId,
    required this.orgName,
    required this.projectId,
    required this.projectName,
    required this.assignedInspector,
    required this.status,
    required this.overallResult,
    required this.governmentReview,
    required this.assignedDate,
    this.submittedDate,
    required this.reason,
    this.latitude,
    this.longitude,
    this.capturedTimestamp,
    this.checklistResults = const {},
    this.photoWatermarkData = const {},
    this.photoUrl,
    this.observations = '',
    this.sha256Hash,
  });

  InspectionModel copyWith({
    String? status,
    String? overallResult,
    String? governmentReview,
    String? submittedDate,
    double? latitude,
    double? longitude,
    String? capturedTimestamp,
    Map<String, String>? checklistResults,
    Map<String, dynamic>? photoWatermarkData,
    String? photoUrl,
    String? observations,
    String? sha256Hash,
  }) {
    return InspectionModel(
      inspectionId: inspectionId,
      orgId: orgId,
      orgName: orgName,
      projectId: projectId,
      projectName: projectName,
      assignedInspector: assignedInspector,
      status: status ?? this.status,
      overallResult: overallResult ?? this.overallResult,
      governmentReview: governmentReview ?? this.governmentReview,
      assignedDate: assignedDate,
      submittedDate: submittedDate ?? this.submittedDate,
      reason: reason,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      capturedTimestamp: capturedTimestamp ?? this.capturedTimestamp,
      checklistResults: checklistResults ?? this.checklistResults,
      photoWatermarkData: photoWatermarkData ?? this.photoWatermarkData,
      photoUrl: photoUrl ?? this.photoUrl,
      observations: observations ?? this.observations,
      sha256Hash: sha256Hash ?? this.sha256Hash,
    );
  }
}

class AuditLogModel {
  final String user;
  final String role; // Admin, Inspector, NGO Officer
  final String action;
  final String entity;
  final String timestamp;

  AuditLogModel({
    required this.user,
    required this.role,
    required this.action,
    required this.entity,
    required this.timestamp,
  });
}

class IssueReportModel {
  final String id;
  final String orgId;
  final String orgName;
  final String subject;
  final String description;
  final String priority; // High, Medium, Low
  final String status; // Submitted, In Review, Resolved
  final String createdAt;

  IssueReportModel({
    required this.id,
    required this.orgId,
    required this.orgName,
    required this.subject,
    required this.description,
    required this.priority,
    required this.status,
    required this.createdAt,
  });
}

class ProgressReportModel {
  final String id;
  final String projectId;
  final String projectName;
  final double progressPct;
  final int beneficiariesServed;
  final String notes;
  final String submittedAt;

  ProgressReportModel({
    required this.id,
    required this.projectId,
    required this.projectName,
    required this.progressPct,
    required this.beneficiariesServed,
    required this.notes,
    required this.submittedAt,
  });
}
