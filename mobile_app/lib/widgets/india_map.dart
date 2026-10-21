import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/app_models.dart';
import 'common_ui.dart';

class IndiaMapWidget extends StatefulWidget {
  final List<OrganizationModel> organizations;
  final List<ProjectModel> projects;
  final ValueChanged<String> onSelectNgo;

  const IndiaMapWidget({
    super.key,
    required this.organizations,
    required this.projects,
    required this.onSelectNgo,
  });

  @override
  State<IndiaMapWidget> createState() => _IndiaMapWidgetState();
}

class _IndiaMapWidgetState extends State<IndiaMapWidget> {
  OrganizationModel? _selectedOrg;
  final MapController _mapController = MapController();

  static const LatLng _indiaCenter = LatLng(20.5937, 78.9629);

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom + 1.0);
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom - 1.0);
  }

  void _resetView() {
    _mapController.move(_indiaCenter, 4.8);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: GovColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GovColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 600;
                final titleBlock = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'National NGO Geo-Distribution (OpenStreetMap)',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: GovColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Interactive OpenStreetMap centered on India • Click any center marker for details',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: GovColors.textMuted),
                    ),
                  ],
                );

                final badgeBlock = Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: GovColors.blueBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${widget.organizations.length} Verified Centers',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: GovColors.slateBlue,
                    ),
                  ),
                );

                return isNarrow
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          titleBlock,
                          const SizedBox(height: 8),
                          badgeBlock,
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: titleBlock),
                          const SizedBox(width: 12),
                          badgeBlock,
                        ],
                      );
              },
            ),
          ),
          const Divider(height: 1, color: GovColors.border),

          // Map Area with OpenStreetMap + Markers + Controls
          LayoutBuilder(
            builder: (context, outerConstraints) {
              final double screenHeight = MediaQuery.of(context).size.height;
              final double mapHeight = (screenHeight * 0.45).clamp(340.0, 520.0);

              return SizedBox(
                height: mapHeight,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(14),
                    bottomRight: Radius.circular(14),
                  ),
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: const MapOptions(
                          initialCenter: _indiaCenter,
                          initialZoom: 4.8,
                          minZoom: 3.0,
                          maxZoom: 18.0,
                          interactionOptions: InteractionOptions(
                            flags: InteractiveFlag.all,
                          ),
                        ),
                        children: [
                          TileLayer(
                            // OSM-based raster tiles. Primary host is OSM France (reliable
                            // on Indian mobile networks); OSM.org is often 403 without UA.
                            urlTemplate:
                                'https://a.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
                            fallbackUrl:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.sih.audit.sih_inspector_app',
                            // Must be a mutable map. TileLayer calls headers.putIfAbsent
                            // for User-Agent, which throws on a const map.
                            tileProvider: NetworkTileProvider(
                              headers: {
                                'User-Agent':
                                    'Drishti/1.0 (com.sih.audit.sih_inspector_app; SIH prototype; contact=sih@local)',
                                'Referer': 'https://www.openstreetmap.org/',
                              },
                            ),
                            maxZoom: 19,
                          ),
                          MarkerLayer(
                            markers: widget.organizations.map((org) {
                              final isSelected = _selectedOrg?.id == org.id;
                              return Marker(
                                point: LatLng(org.latitude, org.longitude),
                                width: 90,
                                height: 58,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedOrg = org;
                                    });
                                  },
                                  child: MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isSelected ? GovColors.navy : GovColors.slateBlue,
                                            borderRadius: BorderRadius.circular(4),
                                            boxShadow: const [
                                              BoxShadow(
                                                color: Colors.black26,
                                                blurRadius: 4,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            org.city,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        Icon(
                                          Icons.location_on,
                                          size: isSelected ? 30 : 24,
                                          color: isSelected ? GovColors.red : GovColors.navy,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),

                      // Map Quick Controls (Zoom in / out / reset)
                      Positioned(
                        left: 14,
                        bottom: 14,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _mapActionButton(
                              icon: Icons.add,
                              tooltip: 'Zoom In',
                              onPressed: _zoomIn,
                            ),
                            const SizedBox(height: 6),
                            _mapActionButton(
                              icon: Icons.remove,
                              tooltip: 'Zoom Out',
                              onPressed: _zoomOut,
                            ),
                            const SizedBox(height: 6),
                            _mapActionButton(
                              icon: Icons.center_focus_strong,
                              tooltip: 'Center on India',
                              onPressed: _resetView,
                            ),
                          ],
                        ),
                      ),

                      // Popup Details Card when an NGO pin is selected
                      if (_selectedOrg != null)
                        _buildPopupCard(context, outerConstraints),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _mapActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.white,
      elevation: 3,
      shadowColor: Colors.black38,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Tooltip(
          message: tooltip,
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            child: Icon(icon, size: 20, color: GovColors.navy),
          ),
        ),
      ),
    );
  }

  Widget _buildPopupCard(BuildContext context, BoxConstraints constraints) {
    final org = _selectedOrg!;
    final orgProjects = widget.projects.where((p) => p.orgId == org.id).toList();
    final totalFunding = orgProjects.fold(0.0, (sum, p) => sum + p.sanctionedAmount);
    final totalBeneficiaries = orgProjects.fold(0, (sum, p) => sum + p.beneficiariesRegistered);

    final double available = constraints.maxWidth.isFinite
        ? constraints.maxWidth
        : MediaQuery.sizeOf(context).width;
    final double popupWidth = (available - 28).clamp(200.0, 360.0);
    final double popupMaxHeight = constraints.maxHeight.isFinite
        ? (constraints.maxHeight - 28).clamp(160.0, constraints.maxHeight)
        : 320.0;

    return Positioned(
      left: 14,
      right: 14,
      top: 14,
      child: Align(
        alignment: Alignment.topRight,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: popupWidth,
            maxHeight: popupMaxHeight,
          ),
          child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: GovColors.slateBlue, width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    org.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: GovColors.navy,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => setState(() => _selectedOrg = null),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                StatusBadge(status: org.sector, compact: true),
                Text(
                  '${org.city}, ${org.state}',
                  style: const TextStyle(fontSize: 12, color: GovColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              decoration: BoxDecoration(
                color: GovColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceAround,
                runSpacing: 8,
                children: [
                  _popupStat('Projects', '${orgProjects.length}'),
                  _popupStat('Funding', FormatHelper.formatCurrency(totalFunding)),
                  _popupStat('Beneficiaries', FormatHelper.formatNumber(totalBeneficiaries)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => widget.onSelectNgo(org.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GovColors.navy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                icon: const Icon(Icons.arrow_forward, size: 14),
                label: const Text(
                  'View Full NGO Profile',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
        ),
          ),
        ),
      ),
    );
  }

  Widget _popupStat(String label, String value) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 72, maxWidth: 110),
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: GovColors.navy),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: GovColors.textMuted),
          ),
        ],
      ),
    );
  }
}
