import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';
import '../../data/repositories/weather_repository_impl.dart';
import '../../domain/entities/weather_entity.dart';
import '../../domain/repositories/weather_repository.dart';

final weatherRepositoryProvider = Provider<WeatherRepository>((ref) {
  return WeatherRepositoryImpl(ref.watch(firestoreProvider));
});

final currentWeatherProvider = StreamProvider.autoDispose<WeatherEntity?>((ref) {
  return ref.watch(weatherRepositoryProvider).watchCurrent();
});
