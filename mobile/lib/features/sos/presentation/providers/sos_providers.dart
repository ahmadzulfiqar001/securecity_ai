import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';
import '../../data/repositories/sos_repository_impl.dart';
import '../../domain/repositories/sos_repository.dart';

final sosRepositoryProvider = Provider<SosRepository>((ref) {
  return SosRepositoryImpl(ref.watch(firestoreProvider));
});
