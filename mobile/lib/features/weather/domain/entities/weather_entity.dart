/// Latest weather snapshot for the user's city, written to
/// `AppConstants.colWeatherData` by authorities/the ingestion pipeline (see
/// `firestore.rules`' `weather_data/{docId}` block). Read-only from the
/// mobile app.
class WeatherEntity {
  final String condition; // 'sunny' | 'cloudy' | 'rainy' | 'stormy' | 'foggy'
  final double temperatureCelsius;
  final String description;
  final String zoneName;
  final DateTime updatedAt;

  WeatherEntity({
    required this.condition,
    required this.temperatureCelsius,
    required this.description,
    required this.zoneName,
    required this.updatedAt,
  });
}
