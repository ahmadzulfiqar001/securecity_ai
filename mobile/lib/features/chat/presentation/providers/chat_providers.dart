import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/presentation/providers/nearby_services_providers.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../domain/repositories/chat_repository.dart';

/// A fresh chat session (and its own conversation history) per screen
/// visit - seeded with whatever nearby-services data is already loaded so
/// the assistant can answer "nearest hospital/police" questions with real
/// data instead of inventing one.
final chatRepositoryProvider = Provider.autoDispose<ChatRepository>((ref) {
  final nearbyServices = ref.watch(nearbyServicesStreamProvider).value ?? const [];
  return ChatRepositoryImpl(nearbyServices: nearbyServices);
});
