import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
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

class _PickedMedia {
  _PickedMedia({required this.file, required this.isVideo});

  final XFile file;
  final bool isVideo;
}

class ReportIncidentScreen extends ConsumerStatefulWidget {
  const ReportIncidentScreen({super.key});

  @override
  ConsumerState<ReportIncidentScreen> createState() => _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends ConsumerState<ReportIncidentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _picker = ImagePicker();

  String _selectedType = 'ROBBERY';
  bool _isAnonymous = false;
  bool _isSubmitting = false;
  String? _uploadStatus;
  final List<_PickedMedia> _pickedMedia = [];

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

  bool get _mediaLimitReached => _pickedMedia.length >= AppConstants.maxIncidentMediaCount;

  Future<void> _addMedia({required bool isVideo, required ImageSource source}) async {
    if (_mediaLimitReached) {
      AppSnackbar.showError(
        context,
        'You can attach up to ${AppConstants.maxIncidentMediaCount} files per report.',
      );
      return;
    }

    final file = isVideo
        ? await _picker.pickVideo(source: source)
        : await _picker.pickImage(source: source, imageQuality: AppConstants.imageQuality);

    if (file == null || !mounted) return;

    final sizeBytes = await File(file.path).length();
    final maxBytes = isVideo ? AppConstants.maxVideoFileSizeBytes : AppConstants.maxImageFileSizeBytes;
    if (sizeBytes > maxBytes) {
      if (mounted) {
        AppSnackbar.showError(
          context,
          isVideo ? 'Video must be under 100 MB.' : 'Photo must be under 10 MB.',
        );
      }
      return;
    }

    setState(() => _pickedMedia.add(_PickedMedia(file: file, isVideo: isVideo)));
  }

  void _showMediaPicker() {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: AppColors.accentCyan),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _addMedia(isVideo: false, source: ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.accentCyan),
              title: const Text('Choose Photo from Gallery'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _addMedia(isVideo: false, source: ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam_outlined, color: AppColors.accentCyan),
              title: const Text('Record Video'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _addMedia(isVideo: true, source: ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.video_library_outlined, color: AppColors.accentCyan),
              title: const Text('Choose Video from Gallery'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _addMedia(isVideo: true, source: ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<List<String>> _uploadMedia(String uid, String incidentId) async {
    if (_pickedMedia.isEmpty) return const [];

    final uploadService = ref.read(storageUploadServiceProvider);
    final urls = <String>[];

    for (var i = 0; i < _pickedMedia.length; i++) {
      final media = _pickedMedia[i];
      if (mounted) {
        setState(() => _uploadStatus = 'Uploading evidence ${i + 1} of ${_pickedMedia.length}…');
      }
      final path = '${AppConstants.storageIncidentMedia}/$uid/$incidentId/${i}_${media.file.name}';
      try {
        final url = await uploadService.uploadFile(
          path: path,
          file: File(media.file.path),
          contentType: media.isVideo ? 'video/mp4' : 'image/jpeg',
        );
        urls.add(url);
      } catch (_) {
        // Non-fatal: submit the report without this one file rather than
        // blocking the whole report on a single flaky upload.
      }
    }

    return urls;
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _uploadStatus = null;
    });

    final locationService = ref.read(locationServiceProvider);
    final pos = await locationService.getCurrentLocation();
    final currentUser = ref.read(firebaseAuthProvider).currentUser;
    final uid = currentUser?.uid ?? '';

    final incidentRepository = ref.read(incidentRepositoryProvider);
    final incidentId = incidentRepository.newIncidentId();
    final evidenceUrls = await _uploadMedia(uid, incidentId);

    if (!mounted) return;
    setState(() => _uploadStatus = null);

    final now = DateTime.now().toUtc().toIso8601String();
    final incident = IncidentEntity(
      reporterId: uid,
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      incidentType: _selectedType,
      severity: 'MEDIUM',
      isAnonymous: _isAnonymous,
      status: 'PENDING',
      location: pos != null ? [pos.longitude, pos.latitude] : [67.0011, 24.8607],
      address: 'Current Location',
      evidenceUrls: evidenceUrls,
      createdAt: now,
      updatedAt: now,
    );

    final result = await incidentRepository.submitIncident(incidentId, incident);

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

              // Evidence / media attachments
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(AppStrings.incidentAddMedia, style: AppTypography.darkTitleSmall),
                  Text(
                    '${_pickedMedia.length}/${AppConstants.maxIncidentMediaCount}',
                    style: AppTypography.darkLabelMedium,
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.paddingSmall),
              SizedBox(
                height: 88,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (var i = 0; i < _pickedMedia.length; i++) _MediaThumbnail(
                      media: _pickedMedia[i],
                      onRemove: () => setState(() => _pickedMedia.removeAt(i)),
                    ),
                    if (!_mediaLimitReached)
                      GestureDetector(
                        onTap: _showMediaPicker,
                        child: Container(
                          width: 72,
                          height: 72,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: AppColors.darkCardElevated,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.darkBorder),
                          ),
                          child: const Icon(Icons.add_a_photo_outlined, color: AppColors.accentCyan),
                        ),
                      ),
                  ],
                ),
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
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: AppColors.primaryDeepBlue,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('SUBMIT REPORT'),
              ),
              if (_uploadStatus != null) ...[
                const SizedBox(height: AppConstants.paddingSmall),
                Text(
                  _uploadStatus!,
                  textAlign: TextAlign.center,
                  style: AppTypography.darkBodySmall,
                ),
              ],
            ],
          ),
        ).animate().fadeIn(duration: motionDuration(context, AppDurations.pageTransition)).slideY(begin: 0.05, end: 0),
      ),
    );
  }
}

class _MediaThumbnail extends StatelessWidget {
  const _MediaThumbnail({required this.media, required this.onRemove});

  final _PickedMedia media;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: media.isVideo
                ? const ColoredBox(
                    color: AppColors.darkCardElevated,
                    child: Icon(Icons.videocam, color: AppColors.accentCyan),
                  )
                : Image.file(File(media.file.path), fit: BoxFit.cover),
          ),
          Positioned(
            top: 2,
            right: 2,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(color: AppColors.emergencyRed, shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 14, color: AppColors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
