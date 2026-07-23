import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _connectivityStreamProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

/// Whether the device currently has *some* network transport (wifi/mobile/
/// ethernet/etc.) available. This is link-layer connectivity, not a
/// guarantee the internet or Firebase is actually reachable - good enough
/// for "you're offline" banner purposes, not a substitute for handling
/// individual request failures.
///
/// Defaults to `true` (assume online) while the first platform check is
/// still in flight or if it errors, so a slow/failed connectivity check on
/// cold start doesn't flash a false "you're offline" banner.
final isOnlineProvider = Provider<bool>((ref) {
  final connectivity = ref.watch(_connectivityStreamProvider);
  return connectivity.when(
    data: (results) => results.any((r) => r != ConnectivityResult.none),
    loading: () => true,
    error: (_, __) => true,
  );
});
