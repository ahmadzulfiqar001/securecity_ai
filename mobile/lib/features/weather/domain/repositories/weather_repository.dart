import '../entities/weather_entity.dart';

abstract class WeatherRepository {
  /// Most recently published weather snapshot, or `null` if none exists yet.
  Stream<WeatherEntity?> watchCurrent();
}
