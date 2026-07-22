import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/weather_entity.dart';
import '../../domain/repositories/weather_repository.dart';

class WeatherRepositoryImpl implements WeatherRepository {
  final FirebaseFirestore _firestore;

  WeatherRepositoryImpl(this._firestore);

  @override
  Stream<WeatherEntity?> watchCurrent() {
    return _firestore
        .collection(AppConstants.colWeatherData)
        .orderBy('updatedAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) => snapshot.docs.isEmpty ? null : _fromDoc(snapshot.docs.first));
  }

  WeatherEntity _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return WeatherEntity(
      condition: data['condition'] as String? ?? 'sunny',
      temperatureCelsius: (data['temperatureCelsius'] as num?)?.toDouble() ?? 0.0,
      description: data['description'] as String? ?? '',
      zoneName: data['zoneName'] as String? ?? 'Your Area',
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
