import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/cards/glass_card.dart';
import '../../../weather/domain/entities/weather_entity.dart';

(IconData, Color) _weatherStyle(String condition) => switch (condition) {
      'rainy' => (Icons.water_drop_outlined, AppColors.infoBlue),
      'stormy' => (Icons.thunderstorm_outlined, AppColors.emergencyOrange),
      'cloudy' => (Icons.cloud_outlined, AppColors.darkTextSecondary),
      'foggy' => (Icons.blur_on, AppColors.darkTextSecondary),
      _ => (Icons.wb_sunny_outlined, AppColors.warningAmber),
    };

/// Compact current-weather strip for Home. Renders nothing (not even a
/// placeholder) until real data exists - `weather_data` is authority/
/// pipeline-written and may be empty for a new deployment.
class WeatherStrip extends StatelessWidget {
  const WeatherStrip({super.key, required this.weather});

  final WeatherEntity weather;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _weatherStyle(weather.condition);

    return Semantics(
      label:
          '${weather.zoneName} weather: ${weather.temperatureCelsius.toStringAsFixed(0)} degrees, ${weather.description}',
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(weather.zoneName, style: AppTypography.darkLabelMedium),
                  Text(weather.description, style: AppTypography.darkBodySmall),
                ],
              ),
            ),
            Text(
              '${weather.temperatureCelsius.toStringAsFixed(0)}°C',
              style: AppTypography.darkTitleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
