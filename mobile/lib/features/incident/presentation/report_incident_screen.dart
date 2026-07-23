import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
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

/// Keyword lists for the on-device incident-type suggestion in
/// [_ReportIncidentScreenState._suggestIncidentType]. This is a simple
/// heuristic, not a real ML classifier - there's no backend to call one
/// (see mobile/.env.example, the ai_engine service was removed in the
/// mobile-only pivot). It only ever pre-fills the existing Incident Type
/// dropdown; the user can always override it.
const Map<String, List<String>> _categoryKeywords = {
  'ROBBERY': ['robbery', 'robbed', 'rob ', 'theft', 'thief', 'steal', 'stolen', 'mugging', 'mugged', 'snatch', 'burglar', 'pickpocket'],
  'ACCIDENT': ['accident', 'crash', 'collision', 'hit and run', 'car crash', 'motorbike', 'road accident', 'injured'],
  'FIRE': ['fire', 'burning', 'burnt', 'smoke', 'flames', 'explosion'],
  'FLOOD': ['flood', 'flooding', 'waterlogged', 'water logging', 'heavy rain', 'sewage overflow'],
  'FIGHT': ['fight', 'fighting', 'assault', 'attacked', 'brawl', 'violence', 'beaten', 'stabbed', 'shooting', 'gun'],
  'HARASSMENT': ['harass', 'stalk', 'catcall', 'threatened', 'threatening', 'following me'],
};

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

  // AI-suggested category (client-side heuristic - see _categoryKeywords).
  // Cleared as soon as the user manually touches the dropdown, so it never
  // fights the user's own choice.
  String? _aiSuggestedType;
  bool _categoryManuallySet = false;
  Timer? _classifyDebounce;

  // Captured once on screen entry and shown read-only so the user can
  // confirm what's about to be submitted, instead of it happening silently.
  Position? _position;
  bool _isLoadingLocation = true;
  bool _locationFailed = false;

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
  void initState() {
    super.initState();
    _fetchLocation();
    _titleController.addListener(_onDescriptiveTextChanged);
    _descController.addListener(_onDescriptiveTextChanged);
  }

  @override
  void dispose() {
    _classifyDebounce?.cancel();
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationFailed = false;
    });
    final locationService = ref.read(locationServiceProvider);
    final pos = await locationService.getCurrentLocation();
    if (!mounted) return;
    setState(() {
      _position = pos;
      _isLoadingLocation = false;
      _locationFailed = pos == null;
    });
  }

  void _onDescriptiveTextChanged() {
    _classifyDebounce?.cancel();
    _classifyDebounce = Timer(const Duration(milliseconds: 400), () {
      final suggestion = _suggestIncidentType('${_titleController.text} ${_descController.text}');
      if (!mounted || suggestion == null) return;
      setState(() {
        _aiSuggestedType = suggestion;
        if (!_categoryManuallySet) {
          _selectedType = suggestion;
        }
      });
    });
  }

  /// On-device keyword heuristic - counts hits per category in
  /// [_categoryKeywords] and returns the best match, or null if nothing
  /// scored (leaving the dropdown at its current value).
  String? _suggestIncidentType(String text) {
    final lower = text.toLowerCase();
    String? best;
    var bestScore = 0;
    for (final entry in _categoryKeywords.entries) {
      final score = entry.value.where(lower.contains).length;
      if (score > bestScore) {
        bestScore = score;
        best = entry.key;
      }
    }
    return best;
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

    // The Submit button is disabled while location is unresolved, but this
    // guards against a stray tap between an in-flight retry and rebuild.
    final pos = _position;
    if (pos == null) {
      AppSnackbar.showError(context, 'Location is required. Please retry location above.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _uploadStatus = null;
    });

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
      location: [pos.longitude, pos.latitude],
      address: '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}',
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

              // Location - captured automatically, shown read-only so the
              // user can confirm what's about to be submitted.
              GlassCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingMedium,
                  vertical: AppConstants.paddingSmall,
                ),
                child: Row(
                  children: [
                    Icon(
                      _locationFailed ? Icons.location_off_outlined : Icons.location_on_outlined,
                      color: _locationFailed ? AppColors.warningAmber : AppColors.accentCyan,
                    ),
                    const SizedBox(width: AppConstants.paddingSmall),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Location', style: AppTypography.darkTitleSmall),
                          const SizedBox(height: 2),
                          Text(
                            _isLoadingLocation
                                ? 'Detecting your location…'
                                : _locationFailed
                                    ? 'Unable to get your location. Enable location services and retry.'
                                    : '${_position!.latitude.toStringAsFixed(5)}, ${_position!.longitude.toStringAsFixed(5)}',
                            style: AppTypography.darkBodySmall,
                          ),
                        ],
                      ),
                    ),
                    if (_isLoadingLocation)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentCyan),
                      )
                    else if (_locationFailed)
                      TextButton(onPressed: _fetchLocation, child: const Text('Retry')),
                  ],
                ),
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

              // Dropdown for Incident type, pre-filled by an on-device
              // keyword suggestion from the title/description (see
              // _suggestIncidentType) until the user picks one themselves.
              if (_aiSuggestedType != null && !_categoryManuallySet)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome, size: 14, color: AppColors.accentCyan),
                      const SizedBox(width: 4),
                      Text(
                        'AI suggested from your description - tap to change',
                        style: AppTypography.darkLabelMedium.copyWith(color: AppColors.accentCyan),
                      ),
                    ],
                  ),
                ),
              DropdownButtonFormField<String>(
                // DropdownButtonFormField's initialValue is read once
                // (uncontrolled FormField semantics, like
                // TextFormField.initialValue) - keying on _selectedType
                // forces it to pick up the AI suggestion when it changes
                // programmatically, not just on manual selection.
                key: Key('incident-type-$_selectedType'),
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
                      _categoryManuallySet = true;
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
            child: GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => _FullScreenMediaViewer(media: media, heroTag: media),
                ),
              ),
              child: Hero(
                tag: media,
                child: media.isVideo
                    ? const ColoredBox(
                        color: AppColors.darkCardElevated,
                        child: Icon(Icons.videocam, color: AppColors.accentCyan),
                      )
                    : Image.file(File(media.file.path), fit: BoxFit.cover),
              ),
            ),
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

/// Full-screen preview pushed when a report's attached photo/video thumbnail
/// is tapped, so a citizen can check what they're about to submit as
/// evidence. Hero-animates from the thumbnail it was opened from.
class _FullScreenMediaViewer extends StatefulWidget {
  const _FullScreenMediaViewer({required this.media, required this.heroTag});

  final _PickedMedia media;
  final Object heroTag;

  @override
  State<_FullScreenMediaViewer> createState() => _FullScreenMediaViewerState();
}

class _FullScreenMediaViewerState extends State<_FullScreenMediaViewer> {
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    if (widget.media.isVideo) {
      final controller = VideoPlayerController.file(File(widget.media.file.path));
      _videoController = controller;
      controller.initialize().then((_) {
        if (!mounted) return;
        setState(() {});
        controller.play();
      });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: Center(
        child: Hero(
          tag: widget.heroTag,
          child: widget.media.isVideo ? _buildVideo() : _buildPhoto(),
        ),
      ),
    );
  }

  Widget _buildPhoto() {
    return InteractiveViewer(
      child: Image.file(File(widget.media.file.path)),
    );
  }

  Widget _buildVideo() {
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) {
      return const CircularProgressIndicator(color: AppColors.accentCyan);
    }
    return AspectRatio(
      aspectRatio: controller.value.aspectRatio,
      child: GestureDetector(
        onTap: () => setState(() {
          controller.value.isPlaying ? controller.pause() : controller.play();
        }),
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(controller),
            if (!controller.value.isPlaying)
              const Icon(Icons.play_arrow, size: 72, color: AppColors.white),
          ],
        ),
      ),
    );
  }
}
