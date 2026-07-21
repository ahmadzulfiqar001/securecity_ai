import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_state_view.dart';
import '../../../core/widgets/glass_card.dart';
import '../domain/entities/nearby_service_entity.dart';
import 'providers/nearby_services_providers.dart';

class NearbyServicesScreen extends ConsumerStatefulWidget {
  const NearbyServicesScreen({super.key});

  @override
  ConsumerState<NearbyServicesScreen> createState() => _NearbyServicesScreenState();
}

class _NearbyServicesScreenState extends ConsumerState<NearbyServicesScreen> {
  String? _selectedType;

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(nearbyServicesStreamProvider);
    final positionAsync = ref.watch(currentPositionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Nearby Services')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _TypeChip(
                    label: 'All',
                    selected: _selectedType == null,
                    onSelected: () => setState(() => _selectedType = null),
                  ),
                  for (final type in NearbyServiceType.all)
                    _TypeChip(
                      label: NearbyServiceType.label(type),
                      selected: _selectedType == type,
                      onSelected: () => setState(() => _selectedType = type),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: servicesAsync.when(
              loading: () => const AppLoadingView(),
              error: (error, _) => AppErrorView(message: 'Failed to load nearby services: $error'),
              data: (services) {
                final position = positionAsync.value;
                var filtered = _selectedType == null
                    ? services
                    : services.where((s) => s.type == _selectedType).toList();

                if (position != null) {
                  filtered = filtered
                      .map((s) => s.copyWithDistance(
                            Geolocator.distanceBetween(
                              position.latitude,
                              position.longitude,
                              s.latitude,
                              s.longitude,
                            ),
                          ))
                      .toList()
                    ..sort((a, b) => (a.distanceMeters ?? 0).compareTo(b.distanceMeters ?? 0));
                }

                if (filtered.isEmpty) {
                  return const AppEmptyView(
                    icon: Icons.local_hospital_outlined,
                    message: 'No nearby services found for this filter yet.',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) => _ServiceTile(service: filtered[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.label, required this.selected, required this.onSelected});

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
        selectedColor: AppColors.glassCyan20,
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({required this.service});

  final NearbyServiceEntity service;

  IconData get _icon => switch (service.type) {
        NearbyServiceType.police => Icons.local_police_outlined,
        NearbyServiceType.hospital => Icons.local_hospital_outlined,
        NearbyServiceType.fireStation => Icons.local_fire_department_outlined,
        NearbyServiceType.shelter => Icons.home_outlined,
        NearbyServiceType.pharmacy => Icons.local_pharmacy_outlined,
        _ => Icons.place_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final distanceKm =
        service.distanceMeters != null ? (service.distanceMeters! / 1000).toStringAsFixed(1) : null;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.glassCyan10,
            child: Icon(_icon, color: AppColors.accentCyan),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(service.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  distanceKm != null ? '$distanceKm km · ${service.address}' : service.address,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (service.phone != null)
            IconButton(
              icon: const Icon(Icons.call, color: AppColors.successGreen),
              tooltip: 'Call ${service.name}',
              onPressed: () => launchUrl(Uri(scheme: 'tel', path: service.phone)),
            ),
        ],
      ),
    );
  }
}
