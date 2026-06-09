// lib/features/student/proximity_indicator.dart

import 'package:flutter/material.dart';
import 'package:upastithi_pramaan/core/theme/app_theme.dart';

enum ProximityState { unknown, scanning, near, far }

class ProximityIndicator extends StatelessWidget {
  const ProximityIndicator({
    super.key,
    required this.state,
    this.rssi,
    this.teacherName,
  });

  final ProximityState state;
  final int? rssi;
  final String? teacherName;

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = switch (state) {
      ProximityState.unknown => (Icons.bluetooth_disabled, AppTheme.textDisabled, 'BLE not started'),
      ProximityState.scanning => (Icons.bluetooth_searching, AppTheme.warning, 'Scanning…'),
      ProximityState.near => (Icons.bluetooth_connected, AppTheme.accent, 'In range ✓'),
      ProximityState.far => (Icons.bluetooth, AppTheme.error, 'Too far away'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: color)),
                if (teacherName != null)
                  Text('Session: $teacherName',
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          if (rssi != null)
            Text(
              '${rssi} dBm',
              style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  fontFeatures: const [FontFeature.tabularFigures()]),
            ),
        ],
      ),
    );
  }
}