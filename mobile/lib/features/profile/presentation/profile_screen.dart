import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/session_providers.dart';
import '../../../core/utils/motion.dart';
import '../../../shared/buttons/emergency_button.dart';
import '../../../shared/dialogs/app_snackbar.dart';
import '../../../shared/widgets/avatar.dart';
import 'widgets/profile_menu_item.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _picker = ImagePicker();
  bool _isUploadingPhoto = false;

  Future<void> _pickAndUploadPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: AppColors.accentCyan),
              title: const Text('Take Photo'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.accentCyan),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    final picked = await _picker.pickImage(source: source, imageQuality: AppConstants.imageQuality);
    if (picked == null || !mounted) return;

    final sizeBytes = await File(picked.path).length();
    if (sizeBytes > AppConstants.maxImageFileSizeBytes) {
      if (mounted) AppSnackbar.showError(context, 'Photo must be under 10 MB.');
      return;
    }

    final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
    if (uid == null) return;

    setState(() => _isUploadingPhoto = true);

    try {
      final uploadService = ref.read(storageUploadServiceProvider);
      final path = '${AppConstants.storageProfileImages}/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final url = await uploadService.uploadFile(
        path: path,
        file: File(picked.path),
        contentType: 'image/jpeg',
      );

      final success = await ref.read(updateProfilePhotoProvider)(url);
      if (!mounted) return;

      if (!success) {
        final errorMessage = ref.read(sessionErrorProvider);
        AppSnackbar.showError(context, errorMessage ?? 'Could not update profile photo.');
      }
    } catch (e) {
      if (mounted) AppSnackbar.showError(context, 'Photo upload failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(title: const Text('My Profile')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _isUploadingPhoto ? null : _pickAndUploadPhoto,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Avatar(radius: 54, imageUrl: user?.profilePhotoUrl),
                    if (_isUploadingPhoto)
                      const Positioned.fill(
                        child: CircleAvatar(
                          radius: 54,
                          backgroundColor: AppColors.darkOverlay,
                          child: CircularProgressIndicator(color: AppColors.accentCyan),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.accentCyan,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, size: 16, color: AppColors.primaryDeepBlue),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(user?.fullName ?? 'Citizen', style: AppTypography.darkTitleLarge),
              const SizedBox(height: 8),
              Text(user?.email ?? '', style: AppTypography.darkBodyMedium),
              const SizedBox(height: 48),
              ProfileMenuItem(
                title: 'Medical Info',
                icon: Icons.medical_information_outlined,
                onTap: () => context.push(AppRoutes.medicalInfo),
              ),
              ProfileMenuItem(
                title: 'Trusted Contacts',
                icon: Icons.contact_phone_outlined,
                onTap: () => context.push(AppRoutes.emergencyContacts),
              ),
              ProfileMenuItem(
                title: 'Safety History',
                icon: Icons.history,
                onTap: () => context.push(AppRoutes.journeyHistory),
              ),
              ProfileMenuItem(
                title: 'Settings',
                icon: Icons.settings_outlined,
                onTap: () => context.push(AppRoutes.settings),
              ),
              const Spacer(),
              EmergencyButton(
                label: 'Sign Out',
                icon: Icons.logout,
                onPressed: () async {
                  await ref.read(signOutProvider)();
                  if (context.mounted) {
                    context.go(AppRoutes.login);
                  }
                },
              ),
            ],
          ).animate().fadeIn(duration: motionDuration(context, AppDurations.pageTransition)).slideY(begin: 0.1, end: 0),
        ),
      ),
    );
  }
}
