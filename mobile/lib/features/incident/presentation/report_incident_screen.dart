import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/app_providers.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/utils/motion.dart';
import '../../../shared/dialogs/app_snackbar.dart';
import '../../../shared/cards/glass_card.dart';
import '../domain/entities/incident_entity.dart';
import 'providers/incident_providers.dart';

class ReportIncidentScreen extends ConsumerStatefulWidget {
  const ReportIncidentScreen({super.key});

  @override
  ConsumerState<ReportIncidentScreen> createState() => _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends ConsumerState<ReportIncidentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  String _selectedType = 'ROBBERY';
  bool _isAnonymous = false;
  bool _isSubmitting = false;

  final List<String> _incidentTypes = [
    'ROBBERY',
    'ACCIDENT',
    'FIRE',
    'FLOOD',
    'FIGHT',
    'HARASSMENT',
    'OTHER',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    final locationService = ref.read(locationServiceProvider);
    final pos = await locationService.getCurrentLocation();
    final currentUser = ref.read(firebaseAuthProvider).currentUser;

    final now = DateTime.now().toUtc().toIso8601String();
    final incident = IncidentEntity(
      reporterId: currentUser?.uid ?? '',
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      incidentType: _selectedType,
      severity: 'MEDIUM',
      isAnonymous: _isAnonymous,
      status: 'PENDING',
      location: pos != null ? [pos.longitude, pos.latitude] : [67.0011, 24.8607],
      address: 'Current Location',
      evidenceUrls: const [],
      createdAt: now,
      updatedAt: now,
    );

    final result = await ref.read(incidentRepositoryProvider).submitIncident(incident);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.fold(
      onSuccess: (_) {
        AppSnackbar.showSuccess(context, 'Incident reported successfully! AI is analyzing severity.');
        context.go(AppRoutes.home);
      },
      onError: (failure) {
        AppSnackbar.showError(context, 'Failed to report incident: ${failure.message}');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkCard,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => context.pop(),
        ),
        title: const Text('Report Incident'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Incident Details', style: AppTypography.darkHeadlineSmall),
              const SizedBox(height: AppConstants.paddingSmall),
              Text(
                'Please provide accurate details for quick emergency dispatch.',
                style: AppTypography.darkBodySmall,
              ),
              const SizedBox(height: AppConstants.paddingLarge),

              // Title input
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title / Subject'),
                validator: (val) {
                  if (val == null || val.isEmpty || val.length < 5) {
                    return 'Enter a descriptive title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppConstants.paddingMedium),

              // Dropdown for Incident type
              DropdownButtonFormField<String>(
                initialValue: _selectedType,
                dropdownColor: AppColors.darkCard,
                decoration: const InputDecoration(labelText: 'Incident Type'),
                items: _incidentTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedType = val;
                    });
                  }
                },
              ),
              const SizedBox(height: AppConstants.paddingMedium),

              // Description input
              TextFormField(
                controller: _descController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (val) {
                  if (val == null || val.isEmpty || val.length < 10) {
                    return 'Describe the incident in more detail';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppConstants.paddingLarge),

              // Anonymous toggle
              GlassCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingMedium,
                  vertical: AppConstants.paddingSmall,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Report Anonymously', style: AppTypography.darkTitleSmall),
                          const SizedBox(height: 2),
                          Text(
                            'Hide your name & details from responders.',
                            style: AppTypography.darkBodySmall,
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isAnonymous,
                      activeThumbColor: AppColors.accentCyan,
                      onChanged: (val) {
                        setState(() {
                          _isAnonymous = val;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.paddingXLarge),

              // Submit Button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReport,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: AppColors.primaryDeepBlue,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('SUBMIT REPORT'),
              ),
            ],
          ),
        ).animate().fadeIn(duration: motionDuration(context, AppDurations.pageTransition)).slideY(begin: 0.05, end: 0),
      ),
    );
  }
}
