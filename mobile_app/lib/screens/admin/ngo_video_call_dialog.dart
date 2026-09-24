import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/app_models.dart';
import '../../services/drishti_service.dart';
import '../../widgets/common_ui.dart';

enum _CallState { dialing, connected, ended }

class NgoVideoCallDialog extends StatefulWidget {
  final OrganizationModel organization;

  const NgoVideoCallDialog({
    super.key,
    required this.organization,
  });

  @override
  State<NgoVideoCallDialog> createState() => _NgoVideoCallDialogState();
}

class _NgoVideoCallDialogState extends State<NgoVideoCallDialog> {
  _CallState _state = _CallState.dialing;
  bool _isMuted = false;
  bool _isVideoOff = false;
  bool _isScreenSharing = false;
  bool _isRecording = true;

  int _callSeconds = 0;
  Timer? _callTimer;
  Timer? _connectTimer;

  final TextEditingController _notesController = TextEditingController(
    text: 'Visual identity verified against central registry. Inquired regarding recent milestone beneficiaries.',
  );

  @override
  void initState() {
    super.initState();
    // Simulate connection handshake
    _connectTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) {
        setState(() {
          _state = _CallState.connected;
        });
        _startTimer();
      }
    });
  }

  void _startTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _callSeconds++;
        });
      }
    });
  }

  void _endCall() {
    _connectTimer?.cancel();
    _callTimer?.cancel();

    final durationStr = _formatDuration(_callSeconds);

    // Record audit trail event in DrishtiService
    DrishtiService().addAuditLog(
      user: 'Admin',
      role: 'Admin',
      action: 'VIDEO_TELECONFERENCE_AUDIT',
      entity: 'Official Video Call with ${widget.organization.name} Admin (Duration: $durationStr)',
    );

    setState(() {
      _state = _CallState.ended;
    });
  }

  String _formatDuration(int totalSeconds) {
    final mins = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  void dispose() {
    _connectTimer?.cancel();
    _callTimer?.cancel();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 720),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: GovColors.slateBlue.withValues(alpha: 0.5), width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 30,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              _buildHeader(),
              const Divider(height: 1, color: Color(0xFF334155)),

              // Main Body depending on state
              Expanded(
                child: _state == _CallState.dialing
                    ? _buildDialingView()
                    : _state == _CallState.connected
                        ? _buildConnectedView()
                        : _buildEndedView(),
              ),

              // Bottom Call Controls
              if (_state == _CallState.connected) _buildControlsBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: GovColors.slateBlue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.video_call, color: Color(0xFF60A5FA), size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Direct Video Call: ${widget.organization.name}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'MoSJE WebRTC Gateway • Verified NGO Administrator',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70, size: 20),
            onPressed: () {
              if (_state == _CallState.connected) {
                _endCall();
              }
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDialingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: GovColors.navy,
              border: Border.all(color: const Color(0xFF60A5FA), width: 3),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.4),
                  blurRadius: 24,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 54),
          ),
          const SizedBox(height: 24),
          Text(
            widget.organization.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Connecting to NGO Administrator (${widget.organization.contactPhone})',
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          ),
          const SizedBox(height: 20),
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF60A5FA)),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Negotiating encrypted audio/video peer connection...',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.call_end, size: 18),
            label: const Text('Cancel Call'),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedView() {
    return Row(
      children: [
        // Main Video Area
        Expanded(
          flex: 7,
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Simulated Video Feed Background
                  Container(
                    decoration: const BoxDecoration(
                      gradient: RadialGradient(
                        colors: [Color(0xFF1E293B), Color(0xFF020617)],
                        radius: 0.9,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF334155).withValues(alpha: 0.6),
                            ),
                            child: const Icon(Icons.account_box, color: Colors.white60, size: 72),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'NGO Executive Desk: ${widget.organization.name}',
                            style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Audio Waveform Active • Video Stream Synchronized (30 fps)',
                            style: TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Official Watermark HUD (Top Left)
                  Positioned(
                    top: 14,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'REC LIVE  |  ${_formatDuration(_callSeconds)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // HUD (Top Right: Encryption Badge)
                  Positioned(
                    top: 14,
                    right: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.lock, color: Color(0xFF34D399), size: 14),
                          SizedBox(width: 6),
                          Text(
                            'AES-256 GCM SECURE',
                            style: TextStyle(
                              color: Color(0xFF34D399),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Overlay Banner (Location & Identity)
                  Positioned(
                    bottom: 14,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Geo-Stamp: ${widget.organization.latitude.toStringAsFixed(4)}°N, ${widget.organization.longitude.toStringAsFixed(4)}°E • ${widget.organization.city}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),

                  // PIP: Local User Camera (Bottom Right)
                  Positioned(
                    bottom: 14,
                    right: 14,
                    width: 140,
                    height: 95,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF60A5FA), width: 1.5),
                        boxShadow: const [
                          BoxShadow(color: Colors.black54, blurRadius: 8),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: _isVideoOff
                                ? const Icon(Icons.videocam_off, color: Colors.white38, size: 28)
                                : const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.person_pin, color: Color(0xFF60A5FA), size: 28),
                                      SizedBox(height: 4),
                                      Text('You (Ministry)', style: TextStyle(color: Colors.white70, fontSize: 10)),
                                    ],
                                  ),
                          ),
                          Positioned(
                            bottom: 4,
                            left: 6,
                            child: Icon(
                              _isMuted ? Icons.mic_off : Icons.mic,
                              color: _isMuted ? Colors.redAccent : Colors.greenAccent,
                              size: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Side Notes & Tele-Audit Dossier Panel
        Expanded(
          flex: 4,
          child: Container(
            margin: const EdgeInsets.only(top: 16, bottom: 16, right: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.edit_note, color: Color(0xFF60A5FA), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Live Tele-Audit Notes',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Record ministerial notes during this session for the audit trail ledger:',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: TextField(
                    controller: _notesController,
                    maxLines: null,
                    expands: true,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      hintText: 'Enter field observations, verified particulars, or action items...',
                      hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF334155)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF60A5FA)),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoRow('Official Admin:', 'Dr. Meenakshi Sundaram'),
                      _infoRow('Sector Focus:', widget.organization.sector),
                      _infoRow('Official Phone:', widget.organization.contactPhone),
                      _infoRow('Verified Status:', widget.organization.verificationStatus),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Tele-Audit observation recorded to session dossier'),
                          backgroundColor: GovColors.green,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.bookmark_added, size: 16),
                    label: const Text('Save Note To Dossier', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildControlsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Mute Mic
          _controlBtn(
            icon: _isMuted ? Icons.mic_off : Icons.mic,
            label: _isMuted ? 'Unmute' : 'Mute',
            isActive: _isMuted,
            activeColor: Colors.redAccent,
            onPressed: () => setState(() => _isMuted = !_isMuted),
          ),
          const SizedBox(width: 14),

          // Camera
          _controlBtn(
            icon: _isVideoOff ? Icons.videocam_off : Icons.videocam,
            label: _isVideoOff ? 'Start Video' : 'Stop Video',
            isActive: _isVideoOff,
            activeColor: Colors.redAccent,
            onPressed: () => setState(() => _isVideoOff = !_isVideoOff),
          ),
          const SizedBox(width: 14),

          // Screen Share
          _controlBtn(
            icon: _isScreenSharing ? Icons.stop_screen_share : Icons.screen_share,
            label: _isScreenSharing ? 'Stop Share' : 'Share Screen',
            isActive: _isScreenSharing,
            activeColor: const Color(0xFF10B981),
            onPressed: () => setState(() => _isScreenSharing = !_isScreenSharing),
          ),
          const SizedBox(width: 14),

          // Record Badge
          _controlBtn(
            icon: Icons.fiber_manual_record,
            label: _isRecording ? 'Recording' : 'Record',
            isActive: _isRecording,
            activeColor: Colors.redAccent,
            onPressed: () => setState(() => _isRecording = !_isRecording),
          ),
          const SizedBox(width: 28),

          // End Call Button
          ElevatedButton.icon(
            onPressed: _endCall,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            icon: const Icon(Icons.call_end, size: 20),
            label: const Text('End Teleconference', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _controlBtn({
    required IconData icon,
    required String label,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onPressed,
          style: IconButton.styleFrom(
            backgroundColor: isActive ? activeColor.withValues(alpha: 0.25) : const Color(0xFF334155),
            foregroundColor: isActive ? activeColor : Colors.white70,
            padding: const EdgeInsets.all(12),
          ),
          icon: Icon(icon, size: 20),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive ? activeColor : Colors.white60,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildEndedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green.withValues(alpha: 0.15),
            ),
            child: const Icon(Icons.verified, color: Color(0xFF34D399), size: 54),
          ),
          const SizedBox(height: 20),
          const Text(
            'Teleconference Session Completed',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Total Call Duration: ${_formatDuration(_callSeconds)}',
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock, color: Color(0xFF60A5FA), size: 14),
                SizedBox(width: 8),
                Text(
                  'Encrypted Call Audit Event Logged to National Integrity Ledger',
                  style: TextStyle(color: Color(0xFFE2E8F0), fontSize: 11, fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: GovColors.navy,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Return to NGO Profile', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
