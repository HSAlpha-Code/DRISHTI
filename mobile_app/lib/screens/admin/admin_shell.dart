import 'package:flutter/material.dart';
import '../../widgets/common_ui.dart';
import 'admin_dashboard_tab.dart';
import 'ngo_registry_tab.dart';
import 'ngo_profile_screen.dart';
import 'project_detail_screen.dart';
import 'inspection_list_tab.dart';
import 'audit_log_tab.dart';

/// Admin portal shell — provides the sidebar navigation and manages
/// drill-down from Dashboard/Registry → NGO Profile → Project Detail.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

enum _AdminView { dashboard, ngoRegistry, ngoProfile, projectDetail, inspections, auditLogs }

class _AdminShellState extends State<AdminShell> {
  _AdminView _view = _AdminView.dashboard;
  int _navIndex = 0; // sidebar index

  // Drill-down context
  String? _selectedNgoId;
  String? _selectedProjectId;

  // Sidebar items
  static const List<({String label, IconData icon})> _navItems = [
    (label: 'Dashboard', icon: Icons.dashboard_outlined),
    (label: 'NGO Registry', icon: Icons.domain_outlined),
    (label: 'Inspections', icon: Icons.fact_check_outlined),
    (label: 'Audit Logs', icon: Icons.history_edu_outlined),
  ];

  void _selectNav(int index) {
    setState(() {
      _navIndex = index;
      switch (index) {
        case 0:
          _view = _AdminView.dashboard;
          break;
        case 1:
          _view = _AdminView.ngoRegistry;
          break;
        case 2:
          _view = _AdminView.inspections;
          break;
        case 3:
          _view = _AdminView.auditLogs;
          break;
      }
    });
  }

  void _openNgoProfile(String orgId) {
    setState(() {
      _selectedNgoId = orgId;
      _view = _AdminView.ngoProfile;
    });
  }

  void _openProjectDetail(String projectId) {
    setState(() {
      _selectedProjectId = projectId;
      _view = _AdminView.projectDetail;
    });
  }

  void _backToRegistry() {
    setState(() {
      _view = _AdminView.ngoRegistry;
      _navIndex = 1;
    });
  }

  void _backToNgoProfile() {
    setState(() {
      _view = _AdminView.ngoProfile;
    });
  }

  Widget _buildBody() {
    switch (_view) {
      case _AdminView.dashboard:
        return AdminDashboardTab(onSelectNgo: _openNgoProfile);
      case _AdminView.ngoRegistry:
        return NgoRegistryTab(
          onSelectNgo: _openNgoProfile,
          onAddNgo: () {},
        );
      case _AdminView.ngoProfile:
        if (_selectedNgoId == null) return const SizedBox();
        return NgoProfileScreen(
          orgId: _selectedNgoId!,
          onBack: _backToRegistry,
          onOpenProject: _openProjectDetail,
        );
      case _AdminView.projectDetail:
        if (_selectedProjectId == null) return const SizedBox();
        return ProjectDetailScreen(
          projectId: _selectedProjectId!,
          onBackToNgo: _backToNgoProfile,
          onBackToRegistry: _backToRegistry,
        );
      case _AdminView.inspections:
        return const InspectionListTab();
      case _AdminView.auditLogs:
        return const AuditLogTab();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: MoSJEAppBar(
        portalTitle: 'Admin Portal',
        currentRole: 'Admin',
        onSwitchPortal: () =>
            Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sidebar (desktop/wide)
          if (isWide)
            SizedBox(
              width: 220,
              height: double.infinity,
              child: Container(
                color: GovColors.navy,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: _navItems.length,
                  itemBuilder: (context, index) {
                    final item = _navItems[index];
                    final selected = _navIndex == index;
                    return InkWell(
                      onTap: () => _selectNav(index),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.white.withValues(alpha: 0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              item.icon,
                              color: selected ? Colors.white : Colors.white60,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              item.label,
                              style: TextStyle(
                                color: selected ? Colors.white : Colors.white60,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.normal,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          // Main Content Area — stretched vertically, aligned to top-left
          Expanded(
            child: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: Align(
                alignment: Alignment.topLeft,
                child: _buildBody(),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: _navIndex,
              onDestinationSelected: _selectNav,
              destinations: _navItems
                  .map((item) => NavigationDestination(
                        icon: Icon(item.icon),
                        label: item.label,
                      ))
                  .toList(),
            ),
    );
  }
}
