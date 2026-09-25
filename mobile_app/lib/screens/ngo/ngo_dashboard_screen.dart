import 'package:flutter/material.dart';
import '../../models/app_models.dart';
import '../../services/drishti_service.dart';
import '../../widgets/common_ui.dart';

class NgoDashboardScreen extends StatefulWidget {
  final VoidCallback onSwitchPortal;

  const NgoDashboardScreen({
    super.key,
    required this.onSwitchPortal,
  });

  @override
  State<NgoDashboardScreen> createState() => _NgoDashboardScreenState();
}

class _NgoDashboardScreenState extends State<NgoDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Issue reporting form controllers
  final _issueSubjectController = TextEditingController();
  final _issueDescController = TextEditingController();
  String _issuePriority = 'High';

  // Progress reporting form controllers
  final _progressNotesController = TextEditingController();
  final _beneficiariesServedController = TextEditingController(text: '150');
  double _progressSlider = 80.0;
  String? _selectedProjectId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _issueSubjectController.dispose();
    _issueDescController.dispose();
    _progressNotesController.dispose();
    _beneficiariesServedController.dispose();
    super.dispose();
  }

  void _submitIssue(DrishtiService service, OrganizationModel org) {
    if (_issueSubjectController.text.trim().isEmpty || _issueDescController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both subject and description.')),
      );
      return;
    }

    service.reportIssue(
      orgId: org.id,
      subject: _issueSubjectController.text.trim(),
      description: _issueDescController.text.trim(),
      priority: _issuePriority,
    );

    _issueSubjectController.clear();
    _issueDescController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Grievance / Issue reported directly to MoSJE officials.')),
    );
  }

  void _submitProgress(DrishtiService service, List<ProjectModel> projects) {
    if (projects.isEmpty) return;
    final projectId = _selectedProjectId ?? projects.first.id;
    final count = int.tryParse(_beneficiariesServedController.text.trim()) ?? 0;

    service.submitProgressReport(
      projectId: projectId,
      progressPct: _progressSlider,
      beneficiariesServed: count,
      notes: _progressNotesController.text.trim().isEmpty
          ? 'Regular milestone achievement update'
          : _progressNotesController.text.trim(),
    );

    _progressNotesController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Progress report logged and timestamped successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: DrishtiService(),
      builder: (context, _) {
        final service = DrishtiService();
        final org = service.currentNgo;
        final myProjects = service.projects.where((p) => p.orgId == org.id).toList();
        final myIssues = service.issueReports.where((i) => i.orgId == org.id).toList();
        final myProgressReports = service.progressReports
            .where((r) => myProjects.any((p) => p.id == r.projectId))
            .toList();

        final totalSanctioned = myProjects.fold(0.0, (sum, p) => sum + p.sanctionedAmount);
        final totalReleased = myProjects.fold(0.0, (sum, p) => sum + p.releasedAmount);
        final totalBens = myProjects.fold(0, (sum, p) => sum + p.beneficiariesRegistered);

        return Scaffold(
          backgroundColor: GovColors.background,
          appBar: MoSJEAppBar(
            portalTitle: 'NGO / Institute Portal',
            currentRole: '${org.name} (Officer)',
            onSwitchPortal: widget.onSwitchPortal,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Bar with Organization Details
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: GovColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: GovColors.border),
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 700;
                          final infoBlock = Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: GovColors.navy.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.corporate_fare, color: GovColors.navy, size: 28),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Wrap(
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      spacing: 10,
                                      runSpacing: 4,
                                      children: [
                                        Text(
                                          org.name,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                            color: GovColors.textDark,
                                          ),
                                        ),
                                        StatusBadge(status: org.verificationStatus),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Registration ID: ${org.registrationId} • ${org.city}, ${org.state}',
                                      style: const TextStyle(fontSize: 12, color: GovColors.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );

                          final switcherDropdown = DropdownButton<String>(
                            value: org.id,
                            underline: const SizedBox(),
                            icon: const Icon(Icons.arrow_drop_down, color: GovColors.slateBlue),
                            items: service.organizations.map((o) {
                              return DropdownMenuItem(
                                value: o.id,
                                child: Text(o.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              );
                            }).toList(),
                            onChanged: (newId) {
                              if (newId != null) {
                                setState(() {
                                  service.currentNgoId = newId;
                                });
                              }
                            },
                          );

                          return isNarrow
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    infoBlock,
                                    const SizedBox(height: 12),
                                    const Divider(color: GovColors.border),
                                    Row(
                                      children: [
                                        const Text('Switch Demo Profile:', style: TextStyle(fontSize: 12, color: GovColors.textMuted)),
                                        const SizedBox(width: 8),
                                        Flexible(child: switcherDropdown),
                                      ],
                                    ),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(child: infoBlock),
                                    const SizedBox(width: 12),
                                    switcherDropdown,
                                  ],
                                );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Top 4 Stat Cards with Responsive Columns
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final double width = constraints.maxWidth;
                        final int cols = (width >= 900)
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
                                title: 'Registered Projects',
                                value: '${myProjects.length}',
                                icon: Icons.folder,
                                badgeText: 'Active',
                              ),
                            ),
                            SizedBox(
                              width: cardWidth,
                              child: CurvedStatCard(
                                title: 'Sanctioned Outlay',
                                value: FormatHelper.formatCurrency(totalSanctioned),
                                icon: Icons.currency_rupee,
                                iconBgColor: GovColors.blueBg,
                                iconColor: GovColors.slateBlue,
                              ),
                            ),
                            SizedBox(
                              width: cardWidth,
                              child: CurvedStatCard(
                                title: 'Funds Released',
                                value: FormatHelper.formatCurrency(totalReleased),
                                icon: Icons.account_balance_wallet,
                                iconBgColor: GovColors.greenBg,
                                iconColor: GovColors.green,
                              ),
                            ),
                            SizedBox(
                              width: cardWidth,
                              child: CurvedStatCard(
                                title: 'Beneficiaries Served',
                                value: FormatHelper.formatNumber(totalBens),
                                icon: Icons.groups,
                                iconBgColor: GovColors.amberBg,
                                iconColor: GovColors.amber,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Tab Navigation
                    Container(
                      decoration: BoxDecoration(
                        color: GovColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: GovColors.border),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        labelColor: GovColors.navy,
                        unselectedLabelColor: GovColors.textMuted,
                        indicatorColor: GovColors.navy,
                        indicatorWeight: 3,
                        tabs: const [
                          Tab(text: 'Institutional Profile'),
                          Tab(text: 'Active Projects'),
                          Tab(text: 'Report Issues to MoSJE'),
                          Tab(text: 'Submit Progress Reports'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Tab Content (Responsive Height)
                    SizedBox(
                      height: (MediaQuery.of(context).size.height * 0.72).clamp(520.0, 780.0),
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildProfileTab(org),
                          _buildProjectsTab(myProjects),
                          _buildIssueReportingTab(service, org, myIssues),
                          _buildProgressReportingTab(service, myProjects, myProgressReports),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileTab(OrganizationModel org) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: GovColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: GovColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Institutional Credentials & Facilities',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: GovColors.textDark),
            ),
            const SizedBox(height: 16),
            const Divider(color: GovColors.border),
            const SizedBox(height: 16),
            _infoRow('Official Registration Key', org.registrationId, isKey: true),
            _infoRow('Sector', org.sector),
            _infoRow('Physical Address', org.fullAddress),
            _infoRow('City / State', '${org.city}, ${org.state}'),
            _infoRow('Contact Email', org.contactEmail),
            _infoRow('Official Phone', org.contactPhone),
            _infoRow('GPS Coordinates', '${org.latitude.toStringAsFixed(4)}° N, ${org.longitude.toStringAsFixed(4)}° E'),
            const SizedBox(height: 16),
            const Text(
              'Verified Facilities & Infrastructure Checklist:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: GovColors.textDark),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: org.scopeAndFacilities.map((f) {
                return Chip(
                  avatar: const Icon(Icons.check_circle, size: 16, color: GovColors.green),
                  label: Text(f, style: const TextStyle(fontSize: 12)),
                  backgroundColor: GovColors.background,
                  side: const BorderSide(color: GovColors.border),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool isKey = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: GovColors.textMuted, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isKey ? FontWeight.w700 : FontWeight.w600,
                color: isKey ? GovColors.navy : GovColors.textDark,
                fontFamily: isKey ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectsTab(List<ProjectModel> projects) {
    if (projects.isEmpty) {
      return const Center(child: Text('No projects currently registered.'));
    }

    return ListView.separated(
      itemCount: projects.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, idx) {
        final prj = projects[idx];
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: GovColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: GovColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      prj.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: GovColors.navy),
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(status: prj.status),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Project ID: ${prj.id} • Category: ${prj.category}',
                style: const TextStyle(fontSize: 12, color: GovColors.textMuted),
              ),
              const SizedBox(height: 12),
              Text(
                prj.description,
                style: const TextStyle(fontSize: 13, color: GovColors.textDark),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text('Progress: ${prj.progressPct.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${prj.beneficiariesRegistered} / ${prj.beneficiariesTarget} Beneficiaries',
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: GovColors.textMuted),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: prj.progressPct / 100,
                  minHeight: 8,
                  backgroundColor: GovColors.border,
                  valueColor: const AlwaysStoppedAnimation(GovColors.navy),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: _statItem('Sanctioned', FormatHelper.formatCurrency(prj.sanctionedAmount))),
                  Expanded(child: _statItem('Released', FormatHelper.formatCurrency(prj.releasedAmount))),
                  Expanded(child: _statItem('Spent', FormatHelper.formatCurrency(prj.spentAmount))),
                  Expanded(child: _statItem('Utilization', '${prj.utilizationPct.toStringAsFixed(1)}%')),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: GovColors.textMuted)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: GovColors.textDark)),
      ],
    );
  }

  Widget _buildIssueReportingTab(DrishtiService service, OrganizationModel org, List<IssueReportModel> issues) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reporting Form
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: GovColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: GovColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Report Issue / Grievance to MoSJE Officials',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: GovColors.textDark),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Escalate disbursement delays, inspection queries, or infrastructure requests directly to ministry desk.',
                  style: TextStyle(fontSize: 12, color: GovColors.textMuted),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _issueSubjectController,
                        decoration: const InputDecoration(
                          labelText: 'Subject / Issue Summary',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        initialValue: _issuePriority,
                        decoration: const InputDecoration(
                          labelText: 'Priority',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        items: ['High', 'Medium', 'Low']
                            .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                            .toList(),
                        onChanged: (v) => setState(() => _issuePriority = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _issueDescController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Detailed Explanation & Impact',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () => _submitIssue(service, org),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GovColors.navy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.send, size: 16),
                    label: const Text('Submit Official Ticket'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Submitted Issues List
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: GovColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: GovColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Submitted Issues & Communication Trail',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: GovColors.textDark),
                ),
                const SizedBox(height: 12),
                if (issues.isEmpty)
                  const Text('No issues reported yet.', style: TextStyle(color: GovColors.textMuted))
                else
                  for (final issue in issues) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: GovColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: GovColors.border),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          StatusBadge(status: issue.priority, compact: true),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        issue.subject,
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: GovColors.textDark),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      issue.createdAt,
                                      style: const TextStyle(fontSize: 11, color: GovColors.textMuted),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  issue.description,
                                  style: const TextStyle(fontSize: 12, color: GovColors.textDark),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          StatusBadge(status: issue.status, compact: true),
                        ],
                      ),
                    ),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressReportingTab(
    DrishtiService service,
    List<ProjectModel> projects,
    List<ProgressReportModel> reports,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress Submission Form
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: GovColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: GovColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Submit Periodic Milestone Progress Report',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: GovColors.textDark),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Record beneficiaries trained, curriculum milestones, and expenditure notes for central monitoring.',
                  style: TextStyle(fontSize: 12, color: GovColors.textMuted),
                ),
                const SizedBox(height: 16),
                if (projects.isNotEmpty) ...[
                  DropdownButtonFormField<String>(
                    initialValue: projects.first.id,
                    decoration: const InputDecoration(
                      labelText: 'Select Project',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: projects.map((p) {
                      return DropdownMenuItem(value: p.id, child: Text(p.name));
                    }).toList(),
                    onChanged: (v) => setState(() => _selectedProjectId = v),
                  ),
                  const SizedBox(height: 16),
                ],
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reported Completion: ${_progressSlider.toStringAsFixed(0)}%',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          Slider(
                            value: _progressSlider,
                            min: 0,
                            max: 100,
                            divisions: 20,
                            activeColor: GovColors.navy,
                            onChanged: (val) => setState(() => _progressSlider = val),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: _beneficiariesServedController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Beneficiaries Served',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _progressNotesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Milestone Achievement Notes',
                    hintText: 'e.g. Completed module 3, distributed assistive kits...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () => _submitProgress(service, projects),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GovColors.navy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Log Progress Report'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Submitted Reports History
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: GovColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: GovColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Progress Report History Log',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: GovColors.textDark),
                ),
                const SizedBox(height: 12),
                if (reports.isEmpty)
                  const Text('No reports submitted yet.', style: TextStyle(color: GovColors.textMuted))
                else
                  for (final r in reports) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: GovColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: GovColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: GovColors.navy,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${r.progressPct.toStringAsFixed(0)}%',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r.projectName,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: GovColors.textDark),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  r.notes,
                                  style: const TextStyle(fontSize: 12, color: GovColors.textDark),
                                ),
                              ],
                            ),
                          ),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${r.beneficiariesServed} Beneficiaries',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: GovColors.slateBlue),
                                  textAlign: TextAlign.right,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  r.submittedAt,
                                  style: const TextStyle(fontSize: 10, color: GovColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
