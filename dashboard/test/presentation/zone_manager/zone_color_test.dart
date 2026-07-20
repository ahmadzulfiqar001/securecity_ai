import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:securecity_dashboard/core/theme/app_colors.dart';
import 'package:securecity_dashboard/domain/entities/map_zone_entity.dart';
import 'package:securecity_dashboard/presentation/zone_manager/zone_manager_screen.dart';

void main() {
  group('zoneColor', () {
    test('maps each zone type to a distinct color', () {
      expect(zoneColor(MapZoneType.emergency), AppColors.emergencyRed);
      expect(zoneColor(MapZoneType.floodRisk), Colors.blueAccent);
      expect(zoneColor(MapZoneType.traffic), AppColors.warningAmber);
    });

    test('falls back to a neutral color for an unknown type', () {
      expect(zoneColor('something_else'), AppColors.darkTextSecondary);
    });
  });
}
