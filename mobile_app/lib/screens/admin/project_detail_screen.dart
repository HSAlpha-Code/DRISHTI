import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/app_models.dart';
import '../../services/drishti_service.dart';
import '../../widgets/common_ui.dart';
import 'inspection_review_dialog.dart';

class ProjectDetailScreen extends StatefulWidget {
  final String projectId;
  final VoidCallback onBackToNgo;
  final VoidCallback onBackToRegistry;

  const ProjectDetailScreen({
    super.key,
    required this.projectId,
    required this.onBackToNgo,
    required this.onBackToRegistry,
  });

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // AI & CCTV Live Simulation state
  Timer? _cctvTimer;
  int _simulatedHeadcount = 12;
  double _simulatedRiskScore = 78.5;
  String _simulatedRiskLevel = 'Critical';
  int _simulatedFrameSec = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 9, vsync: this);

    // CCTV & AI frame sampling simulation (1 frame every 6 seconds as specified in plan.md)
    _cctvTimer = Timer.periodic(const Duration(seconds: 6), (timer) {
      if (!mounted) return;
      setState(() {
        _simulatedFrameSec += 6;
        // Subtle headcount oscillation around simulated_classroom_cctv.mp4
        final delta = (timer.tick % 3 == 0) ? 1 : ((timer.tick % 2 == 0) ? -1 : 0);
        _simulatedHeadcount = (_simulatedHeadcount + delta).clamp(9, 18);
        final discrepancy = (35 - _simulatedHeadcount).abs();
        _simulatedRiskScore = (discrepancy / 35.0 * 100.0 * 1.1).clamp(10.0, 95.0);
        if (_simulatedRiskScore >= 65) {
          _simulatedRiskLevel = 'Critical';
        } else if (_simulatedRiskScore >= 35) {
          _simulatedRiskLevel = 'Elevated';
        } else {
          _simulatedRiskLevel = 'Normal';
        }
      });
    });
  }

  @override
  void dispose() {
    _cctvTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _showAddFundingDialog(DrishtiService service, ProjectModel project) {
    final sourceCtrl = TextEditingController(text: 'MoSJE Tranche II Grant');
    final amountCtrl = TextEditingController(text: '800000');
    final purposeCtrl = TextEditingController(text: 'Second Milestone Release');
    final refCtrl = TextEditingController(text: 'REL-PFMS-99402');
    String stage = 'Released';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: GovColors.surface,
        title: const Text('Add Project Funding Tranche', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: sourceCtrl, decoration: const InputDecoration(labelText: 'Funding Source')),
            const SizedBox(height: 10),
            TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (INR)')),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: stage,
              decoration: const InputDecoration(labelText: 'Stage'),
              items: ['Sanctioned', 'Released'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => stage = v!,
            ),
            const SizedBox(height: 10),
            TextField(controller: purposeCtrl, decoration: const InputDecoration(labelText: 'Purpose')),
            const SizedBox(height: 10),
            TextField(controller: refCtrl, decoration: const InputDecoration(labelText: 'Sanction / Reference Number')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final amt = double.tryParse(amountCtrl.text.trim()) ?? 0;
              service.addFunding(
                projectId: project.id,
                source: sourceCtrl.text.trim(),
                stage: stage,
                amount: amt,
                date: DateTime.now().toString().split(' ')[0],
                purpose: purposeCtrl.text.trim(),
                reference: refCtrl.text.trim(),
              );
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: GovColors.navy, foregroundColor: Colors.white),
            child: const Text('Add Funding'),
          ),
        ],
      ),
    );
  }

  void _showAddExpenseDialog(DrishtiService service, ProjectModel project) {
    final purposeCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final vendorCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: GovColors.surface,
        title: const Text('Add Expenditure Record', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: purposeCtrl, decoration: const InputDecoration(labelText: 'Expense Purpose')),
            const SizedBox(height: 10),
            TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (INR)')),
            const SizedBox(height: 10),
            TextField(controller: vendorCtrl, decoration: const InputDecoration(labelText: 'Vendor Name')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final amt = double.tryParse(amountCtrl.text.trim()) ?? 0;
              service.addExpense(
                projectId: project.id,
                purpose: purposeCtrl.text.trim(),
                amount: amt,
                vendor: vendorCtrl.text.trim(),
                date: DateTime.now().toString().split(' ')[0],
              );
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: GovColors.navy, foregroundColor: Colors.white),
            child: const Text('Add Expense'),
          ),
        ],
      ),
    );
  }

  void _showAddBeneficiaryDialog(DrishtiService service, ProjectModel project) {
    final nameCtrl = TextEditingController();
    final ageCtrl = TextEditingController(text: '22');
    final serviceCtrl = TextEditingController(text: 'Assistive Digital Certification');
    String gender = 'Male';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: GovColors.surface,
        title: const Text('Add Beneficiary Enrollment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Beneficiary Name')),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: TextField(controller: ageCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Age'))),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: gender,
                    decoration: const InputDecoration(labelText: 'Gender'),
                    items: ['Male', 'Female', 'Other'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                    onChanged: (v) => gender = v!,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(controller: serviceCtrl, decoration: const InputDecoration(labelText: 'Service Received')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final age = int.tryParse(ageCtrl.text.trim()) ?? 20;
              service.addBeneficiary(
                projectId: project.id,
                name: nameCtrl.text.trim(),
                age: age,
                gender: gender,
                serviceReceived: serviceCtrl.text.trim(),
                date: DateTime.now().toString().split(' ')[0],
              );
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: GovColors.navy, foregroundColor: Colors.white),
            child: const Text('Save Beneficiary'),
          ),
        ],
      ),
    );
  }

  void _openInspectionDossier(InspectionModel inspection) {
    showDialog(
      context: context,
      builder: (ctx) => InspectionReviewDialog(
        inspection: inspection,
        onUpdated: () => setState(() {}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: DrishtiService(),
      builder: (context, _) {
        final service = DrishtiService();
        final project = service.projects.firstWhere(
          (p) => p.id == widget.projectId,
          orElse: () => service.projects.first,
        );
        final org = service.organizations.firstWhere(
          (o) => o.id == project.orgId,
          orElse: () => service.organizations.first,
        );

        final fundings = service.fundings.where((f) => f.projectId == project.id).toList();
        final expenses = service.expenses.where((e) => e.projectId == project.id).toList();
        final documents = service.documents.where((d) => d.projectId == project.id).toList();
        final beneficiaries = service.beneficiaries.where((b) => b.projectId == project.id).toList();
        final cameras = service.cameras.where((c) => c.projectId == project.id).toList();
        final alerts = service.alerts.where((a) => a.projectId == project.id).toList();
        final inspections = service.inspections.where((i) => i.projectId == project.id).toList();
        final progressReports = service.progressReports.where((r) => r.projectId == project.id).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Breadcrumb/path trail at top showing navigation depth
              BreadcrumbsTrail(
                crumbs: ['Admin Console', 'NGO Registry', org.name, project.name],
                onCrumbTap: (idx) {
                  if (idx <= 1) widget.onBackToRegistry();
                  if (idx == 2) widget.onBackToNgo();
                },
              ),
              const SizedBox(height: 16),

              // Heading: project name; subtext: sector, state, city (Responsive)
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 650;
                  final titleBlock = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          Text(
                            project.name,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: GovColors.textDark),
                          ),
                          StatusBadge(status: project.status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sector: ${org.sector} • Location: ${org.city}, ${org.state} • Org: ${org.name}',
                        style: const TextStyle(fontSize: 13, color: GovColors.textMuted),
                      ),
                    ],
                  );

                  final backBtn = OutlinedButton.icon(
                    onPressed: widget.onBackToNgo,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: GovColors.slateBlue,
                      side: const BorderSide(color: GovColors.slateBlue),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: const Text('Back to NGO Profile'),
                  );

                  return isNarrow
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            titleBlock,
                            const SizedBox(height: 12),
                            Align(alignment: Alignment.centerLeft, child: backBtn),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: titleBlock),
                            const SizedBox(width: 16),
                            backBtn,
                          ],
                        );
                },
              ),
              const SizedBox(height: 24),

              // 4 Big Cards: Sanctioned, Released, Spent, Remaining amounts (Responsive dynamic columns)
              LayoutBuilder(
                builder: (context, constraints) {
                  final double width = constraints.maxWidth;
                  final int cols = (width >= 1050)
                      ? 4
                      : (width >= 550)
                          ? 2
                          : 1;
                  final double cardWidth = (width - ((cols - 1) * 16)) / cols;

                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      SizedBox(
                        width: cardWidth,
                        child: CurvedStatCard(
                          title: 'Sanctioned Outlay',
                          value: FormatHelper.formatCurrency(project.sanctionedAmount),
                          subtitle: 'Approved central allocation',
                          icon: Icons.account_balance,
                          iconColor: GovColors.navy,
                          badgeText: 'Sanctioned',
                          badgeBgColor: GovColors.blueBg,
                          badgeColor: GovColors.slateBlue,
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: CurvedStatCard(
                          title: 'Released Amount',
                          value: FormatHelper.formatCurrency(project.releasedAmount),
                          subtitle: 'Disbursed to NGO treasury',
                          icon: Icons.payments,
                          iconColor: GovColors.slateBlue,
                          iconBgColor: GovColors.blueBg,
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: CurvedStatCard(
                          title: 'Spent Amount',
                          value: FormatHelper.formatCurrency(project.spentAmount),
                          subtitle: 'Verified audited expenses',
                          icon: Icons.receipt_long,
                          iconColor: GovColors.amber,
                          iconBgColor: GovColors.amberBg,
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: CurvedStatCard(
                          title: 'Remaining Amount',
                          value: FormatHelper.formatCurrency(project.remainingAmount),
                          subtitle: 'Balance unspent grant',
                          icon: Icons.savings,
                          iconColor: GovColors.green,
                          iconBgColor: GovColors.greenBg,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // 10-Tab Panel Container
              Container(
                decoration: BoxDecoration(
                  color: GovColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: GovColors.border),
                ),
                child: Column(
                  children: [
                    TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      labelColor: GovColors.navy,
                      unselectedLabelColor: GovColors.textMuted,
                      indicatorColor: GovColors.navy,
                      indicatorWeight: 3,
                      tabs: const [
                        Tab(text: 'Overview'),
                        Tab(text: 'Funding'),
                        Tab(text: 'Expenses'),
                        Tab(text: 'Documents'),
                        Tab(text: 'Beneficiaries'),
                        Tab(text: 'Progress'),
                        Tab(text: 'CCTV & AI'),
                        Tab(text: 'Alerts'),
                        Tab(text: 'Inspection History'),
                      ],
                    ),
                    const Divider(height: 1, color: GovColors.border),
                    SizedBox(
                      height: (MediaQuery.of(context).size.height * 0.72).clamp(520.0, 780.0),
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildTabOverview(project, alerts.length),
                          _buildTabFunding(service, project, fundings),
                          _buildTabExpenses(service, project, expenses),
                          _buildTabDocuments(documents),
                          _buildTabBeneficiaries(service, project, beneficiaries),
                          _buildTabProgress(progressReports, project),
                          _buildTabCctvAndAi(cameras, project),
                          _buildTabAlerts(alerts),
                          _buildTabInspectionHistory(inspections),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 1. Overview Tab
  Widget _buildTabOverview(ProjectModel project, int openAlertsCount) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  project.description,
                  style: const TextStyle(fontSize: 14, color: GovColors.textDark, height: 1.4),
                ),
              ),
              const SizedBox(width: 16),
              StatusBadge(status: project.status),
            ],
          ),
          const SizedBox(height: 20),

          // Key metrics row
          Row(
            children: [
              _metricChip('Beneficiaries Count', '${project.beneficiariesRegistered} / ${project.beneficiariesTarget}'),
              const SizedBox(width: 16),
              _metricChip('Funding Utilization', '${project.utilizationPct.toStringAsFixed(1)}%'),
              const SizedBox(width: 16),
              _metricChip('Open Alerts (AI Engine)', '$openAlertsCount Open', isAlert: openAlertsCount > 0),
            ],
          ),
          const SizedBox(height: 24),

          // 2 Nested Cards: Project Information & Financial Position
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nested Card 1: Project Information
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: GovColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: GovColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Project Information',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: GovColors.navy),
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: GovColors.border),
                      const SizedBox(height: 10),
                      _nestedRow('Project ID', project.id),
                      _nestedRow('Category', project.category),
                      _nestedRow('Lifecycle Status', project.status),
                      _nestedRow('Commencement Date', project.startDate),
                      _nestedRow('Target Completion', project.endDate),
                      _nestedRow('Beneficiaries Recorded', '${project.beneficiariesRegistered} individuals'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // Nested Card 2: Financial Position
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: GovColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: GovColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Financial Position',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: GovColors.navy),
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: GovColors.border),
                      const SizedBox(height: 10),
                      _nestedRow('Sanctioned Outlay', FormatHelper.formatCurrency(project.sanctionedAmount)),
                      _nestedRow('Released via DBT', FormatHelper.formatCurrency(project.releasedAmount)),
                      _nestedRow('Spent & Audited', FormatHelper.formatCurrency(project.spentAmount)),
                      _nestedRow('Remaining Grant', FormatHelper.formatCurrency(project.remainingAmount)),
                      _nestedRow('Utilization Ratio', '${project.utilizationPct.toStringAsFixed(1)}%'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricChip(String label, String value, {bool isAlert = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isAlert ? GovColors.redBg : GovColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isAlert ? GovColors.red : GovColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: isAlert ? GovColors.red : GovColors.textMuted)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: isAlert ? GovColors.red : GovColors.textDark)),
          ],
        ),
      ),
    );
  }

  Widget _nestedRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: GovColors.textMuted)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: GovColors.textDark)),
        ],
      ),
    );
  }

  // 2. Funding Tab
  Widget _buildTabFunding(DrishtiService service, ProjectModel project, List<FundingModel> fundings) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Grant Allocations & Tranche Disbursements', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: GovColors.textDark)),
              ElevatedButton.icon(
                onPressed: () => _showAddFundingDialog(service, project),
                style: ElevatedButton.styleFrom(backgroundColor: GovColors.navy, foregroundColor: Colors.white),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Funding'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DataTable(
            columns: const [
              DataColumn(label: Text('Funding Source')),
              DataColumn(label: Text('Stage')),
              DataColumn(label: Text('Amount')),
              DataColumn(label: Text('Disbursement Date')),
              DataColumn(label: Text('Purpose')),
              DataColumn(label: Text('Reference No.')),
            ],
            rows: fundings.map((f) => DataRow(cells: [
              DataCell(Text(f.source, style: const TextStyle(fontWeight: FontWeight.w600))),
              DataCell(StatusBadge(status: f.stage, compact: true)),
              DataCell(Text(FormatHelper.formatCurrency(f.amount), style: const TextStyle(fontWeight: FontWeight.w700))),
              DataCell(Text(f.date)),
              DataCell(Text(f.purpose)),
              DataCell(Text(f.reference, style: const TextStyle(fontFamily: 'monospace'))),
            ])).toList(),
          ),
        ],
      ),
    );
  }

  // 3. Expenses Tab
  Widget _buildTabExpenses(DrishtiService service, ProjectModel project, List<ExpenseModel> expenses) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Audited Expenditure Records', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: GovColors.textDark)),
              ElevatedButton.icon(
                onPressed: () => _showAddExpenseDialog(service, project),
                style: ElevatedButton.styleFrom(backgroundColor: GovColors.navy, foregroundColor: Colors.white),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Expense'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DataTable(
            columns: const [
              DataColumn(label: Text('TXN ID')),
              DataColumn(label: Text('Purpose')),
              DataColumn(label: Text('Amount')),
              DataColumn(label: Text('Vendor / Payee')),
              DataColumn(label: Text('Date')),
              DataColumn(label: Text('Audit Status')),
            ],
            rows: expenses.map((e) => DataRow(cells: [
              DataCell(Text(e.txnId, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w700))),
              DataCell(Text(e.purpose)),
              DataCell(Text(FormatHelper.formatCurrency(e.amount), style: const TextStyle(fontWeight: FontWeight.w700))),
              DataCell(Text(e.vendor)),
              DataCell(Text(e.date)),
              DataCell(StatusBadge(status: e.status, compact: true)),
            ])).toList(),
          ),
        ],
      ),
    );
  }

  // 4. Documents Tab
  Widget _buildTabDocuments(List<DocumentModel> documents) {
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: documents.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, idx) {
        final doc = documents[idx];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: GovColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: GovColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.picture_as_pdf, color: GovColors.red, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(doc.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: GovColors.textDark)),
                    const SizedBox(height: 2),
                    Text('Type: ${doc.docType} • Size: ${doc.fileSize} • Uploaded: ${doc.uploadedAt}', style: const TextStyle(fontSize: 11, color: GovColors.textMuted)),
                    const SizedBox(height: 2),
                    Text('SHA-256: ${doc.sha256Hash.substring(0, 24)}...', style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: GovColors.navy)),
                  ],
                ),
              ),
              StatusBadge(status: 'Verified', compact: true),
            ],
          ),
        );
      },
    );
  }

  // 5. Beneficiaries Tab
  Widget _buildTabBeneficiaries(DrishtiService service, ProjectModel project, List<BeneficiaryModel> beneficiaries) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Enrolled Beneficiary Registry', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: GovColors.textDark)),
              ElevatedButton.icon(
                onPressed: () => _showAddBeneficiaryDialog(service, project),
                style: ElevatedButton.styleFrom(backgroundColor: GovColors.navy, foregroundColor: Colors.white),
                icon: const Icon(Icons.person_add, size: 16),
                label: const Text('Add Beneficiary'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DataTable(
            columns: const [
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('Age')),
              DataColumn(label: Text('Gender')),
              DataColumn(label: Text('Service Received')),
              DataColumn(label: Text('Enrollment Date')),
            ],
            rows: beneficiaries.map((b) => DataRow(cells: [
              DataCell(Text(b.name, style: const TextStyle(fontWeight: FontWeight.w600))),
              DataCell(Text('${b.age}')),
              DataCell(Text(b.gender)),
              DataCell(Text(b.serviceReceived)),
              DataCell(Text(b.date)),
            ])).toList(),
          ),
        ],
      ),
    );
  }

  // 6. Progress Tab
  Widget _buildTabProgress(List<ProgressReportModel> reports, ProjectModel project) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reported Progress: ${project.progressPct.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: project.progressPct / 100,
              minHeight: 10,
              backgroundColor: GovColors.border,
              valueColor: const AlwaysStoppedAnimation(GovColors.navy),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Milestone Log Submissions:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          for (final r in reports)
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: GovColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: GovColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: GovColors.navy, borderRadius: BorderRadius.circular(6)),
                    child: Text('${r.progressPct.toStringAsFixed(0)}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.notes, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        Text('Beneficiaries Served: ${r.beneficiariesServed} • Submitted: ${r.submittedAt}', style: const TextStyle(fontSize: 11, color: GovColors.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // 7. CCTV & AI Tab
  Widget _buildTabCctvAndAi(List<CameraModel> cameras, ProjectModel project) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Classroom CCTV & YOLOv11 Headcount Engine', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: GovColors.textDark)),
                  const SizedBox(height: 2),
                  Text('OpenCV Frame Sampling: 1 frame/6s • Ultralytics YOLOv11 Headcount Detection (test.py)', style: const TextStyle(fontSize: 12, color: GovColors.textMuted)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: GovColors.greenBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.fiber_manual_record, color: GovColors.green, size: 10),
                    SizedBox(width: 6),
                    Text('LIVE AI STREAM', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: GovColors.green)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Video Feed Simulation Box
          Container(
            height: 280,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: GovColors.border),
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.videocam, color: Colors.white30, size: 54),
                      const SizedBox(height: 10),
                      Text(
                        'Classroom Cam 101: simulated_classroom_cctv.mp4',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      Text(
                        'Sampling interval: ${_simulatedFrameSec}s elapsed',
                        style: const TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                // Headcount badge (from test.py)
                Positioned(
                  left: 20,
                  top: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.green, width: 1.5),
                    ),
                    child: Text(
                      'Classroom Count: $_simulatedHeadcount',
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
                // Camera status top right
                Positioned(
                  right: 20,
                  top: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    color: Colors.black.withValues(alpha: 0.7),
                    child: const Text(
                      'YOLOv11 • conf=0.15 • imgsz=960',
                      style: TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'monospace'),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Risk Scoring Engine Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: GovColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: GovColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Dynamic Risk Scoring Engine', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: GovColors.navy)),
                      const SizedBox(height: 4),
                      Text(
                        'Formula: Discrepancy % between expected (35) vs detected ($_simulatedHeadcount). Discrepancy > 60% spikes severity to Critical.',
                        style: const TextStyle(fontSize: 12, color: GovColors.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${_simulatedRiskScore.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _simulatedRiskLevel == 'Critical' ? GovColors.red : GovColors.amber,
                      ),
                    ),
                    StatusBadge(status: _simulatedRiskLevel, compact: true),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 8. Alerts Tab
  Widget _buildTabAlerts(List<AlertModel> alerts) {
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: alerts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, idx) {
        final a = alerts[idx];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: GovColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: GovColors.border),
          ),
          child: Row(
            children: [
              StatusBadge(status: a.severity, compact: true),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.reason, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: GovColors.textDark)),
                    const SizedBox(height: 2),
                    Text('Triggered: ${a.createdAt} • Status: ${a.status}', style: const TextStyle(fontSize: 11, color: GovColors.textMuted)),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Alert ticket ${a.id} dispatched to Inspection Queue.')),
                  );
                },
                child: const Text('Manage ->', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        );
      },
    );
  }

  // 9. Inspection History Tab
  Widget _buildTabInspectionHistory(List<InspectionModel> inspections) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Field Audit & Inspection Records', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: GovColors.textDark)),
          const SizedBox(height: 16),
          DataTable(
            columns: const [
              DataColumn(label: Text('Inspection ID')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Result')),
              DataColumn(label: Text('Government Review')),
              DataColumn(label: Text('Submitted')),
              DataColumn(label: Text('Action')),
            ],
            rows: inspections.map((i) => DataRow(cells: [
              DataCell(Text(i.inspectionId, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w700))),
              DataCell(StatusBadge(status: i.status, compact: true)),
              DataCell(StatusBadge(status: i.overallResult, compact: true)),
              DataCell(StatusBadge(status: i.governmentReview, compact: true)),
              DataCell(Text(i.submittedDate ?? 'Pending')),
              DataCell(
                ElevatedButton(
                  onPressed: () => _openInspectionDossier(i),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GovColors.navy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                  child: const Text('View ->', style: TextStyle(fontSize: 12)),
                ),
              ),
            ])).toList(),
          ),
        ],
      ),
    );
  }
}
