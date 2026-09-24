import 'package:flutter/material.dart';
import '../../services/drishti_service.dart';
import '../../widgets/common_ui.dart';

class NgoRegistryTab extends StatefulWidget {
  final ValueChanged<String> onSelectNgo;
  final VoidCallback onAddNgo;

  const NgoRegistryTab({
    super.key,
    required this.onSelectNgo,
    required this.onAddNgo,
  });

  @override
  State<NgoRegistryTab> createState() => _NgoRegistryTabState();
}

class _NgoRegistryTabState extends State<NgoRegistryTab> {
  final _searchController = TextEditingController();
  String _selectedSector = 'All';
  String _selectedState = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = DrishtiService();
    final allOrgs = service.organizations;

    // Filter Logic
    final filtered = allOrgs.where((org) {
      final matchesSearch = _searchController.text.isEmpty ||
          org.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          org.registrationId.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          org.city.toLowerCase().contains(_searchController.text.toLowerCase());

      final matchesSector = _selectedSector == 'All' || org.sector == _selectedSector;
      final matchesState = _selectedState == 'All' || org.state == _selectedState;

      return matchesSearch && matchesSector && matchesState;
    }).toList();

    final sectors = ['All', 'Education', 'Healthcare', 'Women Welfare', 'Skill Development', 'Social Defense'];
    final states = ['All', 'Delhi', 'Maharashtra', 'Karnataka', 'Telangana', 'West Bengal', 'Tamil Nadu'];

    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Heading and Add NGO Button (Responsive)
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 650;
                final titleBlock = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'NGO & Institutional Registry',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: GovColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'National directory of verified non-profit institutes and organizations receiving grants',
                      style: TextStyle(fontSize: 13, color: GovColors.textMuted),
                    ),
                  ],
                );

                final addBtn = ElevatedButton.icon(
                  onPressed: widget.onAddNgo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GovColors.navy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.add_business, size: 18),
                  label: const Text('Add NGO / Institute'),
                );

                return isNarrow
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          titleBlock,
                          const SizedBox(height: 12),
                          Align(alignment: Alignment.centerLeft, child: addBtn),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: titleBlock),
                          const SizedBox(width: 16),
                          addBtn,
                        ],
                      );
              },
            ),
            const SizedBox(height: 20),

            // Responsive Filters Bar: Search box, Sector Filter, State Filter
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: GovColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: GovColors.border),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 750;

                  final searchField = TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search by NGO Name, Registration Number, or City...',
                      prefixIcon: const Icon(Icons.search, size: 20, color: GovColors.textMuted),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  );

                  final sectorDropdown = DropdownButtonFormField<String>(
                    value: _selectedSector,
                    decoration: InputDecoration(
                      labelText: 'Sector Filter',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: sectors.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setState(() => _selectedSector = v!),
                  );

                  final stateDropdown = DropdownButtonFormField<String>(
                    value: _selectedState,
                    decoration: InputDecoration(
                      labelText: 'State Filter',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: states.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setState(() => _selectedState = v!),
                  );

                  if (isNarrow) {
                    return Column(
                      children: [
                        searchField,
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: sectorDropdown),
                            const SizedBox(width: 12),
                            Expanded(child: stateDropdown),
                          ],
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(flex: 3, child: searchField),
                      const SizedBox(width: 14),
                      Expanded(flex: 2, child: sectorDropdown),
                      const SizedBox(width: 14),
                      Expanded(flex: 2, child: stateDropdown),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Table: Expands to full screen width, horizontally scrollable on mobile
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: GovColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: GovColors.border),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: constraints.maxWidth,
                        ),
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
                          headingTextStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: GovColors.navy,
                          ),
                          columnSpacing: (constraints.maxWidth > 950) ? 24 : 16,
                          dataRowMinHeight: 56,
                          dataRowMaxHeight: 64,
                          columns: const [
                            DataColumn(label: Text('NGO / Institute Name')),
                            DataColumn(label: Text('City')),
                            DataColumn(label: Text('State')),
                            DataColumn(label: Text('Sector')),
                            DataColumn(label: Text('Registration Number')),
                            DataColumn(label: Text('Verification Status')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: filtered.map((org) {
                            return DataRow(
                              cells: [
                                DataCell(
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        org.name,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: GovColors.textDark,
                                        ),
                                      ),
                                      Text(
                                        org.contactEmail,
                                        style: const TextStyle(fontSize: 11, color: GovColors.textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                                DataCell(Text(org.city, style: const TextStyle(fontSize: 13))),
                                DataCell(Text(org.state, style: const TextStyle(fontSize: 13))),
                                DataCell(StatusBadge(status: org.sector, compact: true)),
                                DataCell(
                                  Text(
                                    org.registrationId,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'monospace',
                                      color: GovColors.navy,
                                    ),
                                  ),
                                ),
                                DataCell(StatusBadge(status: org.verificationStatus, compact: true)),
                                DataCell(
                                  OutlinedButton.icon(
                                    onPressed: () => widget.onSelectNgo(org.id),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: GovColors.slateBlue,
                                      side: const BorderSide(color: GovColors.slateBlue),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                    ),
                                    icon: const Icon(Icons.open_in_new, size: 14),
                                    label: const Text('View Profile ->', style: TextStyle(fontSize: 12)),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
