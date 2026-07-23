import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/providers/session_providers.dart';
import '../../../core/utils/motion.dart';
import '../../../shared/cards/glass_card.dart';
import '../../../shared/dialogs/app_snackbar.dart';

const List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

class MedicalInfoScreen extends ConsumerStatefulWidget {
  const MedicalInfoScreen({super.key});

  @override
  ConsumerState<MedicalInfoScreen> createState() => _MedicalInfoScreenState();
}

class _MedicalInfoScreenState extends ConsumerState<MedicalInfoScreen> {
  late final TextEditingController _notesController;
  String? _bloodGroup;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _bloodGroup = user?.bloodGroup;
    _notesController = TextEditingController(text: user?.medicalNotes ?? '');
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    final notes = _notesController.text.trim();
    final success = await ref.read(updateMedicalInfoProvider)(
      bloodGroup: _bloodGroup,
      medicalNotes: notes.isEmpty ? null : notes,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      AppSnackbar.showSuccess(context, 'Medical info saved.');
    } else {
      final errorMessage = ref.read(sessionErrorProvider);
      AppSnackbar.showError(context, errorMessage ?? 'Could not save medical info.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(title: const Text('Medical Info')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            GlassCard(
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, color: AppColors.accentCyan),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Visible to you and to responding authorities (police/ambulance/fire) '
                      'during an incident or SOS - not shared with anyone else.',
                      style: AppTypography.darkBodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text('Blood Group', style: AppTypography.darkTitleSmall),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              initialValue: _bloodGroup,
              dropdownColor: AppColors.darkCard,
              decoration: const InputDecoration(hintText: 'Not set'),
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('Not set')),
                for (final group in _bloodGroups) DropdownMenuItem(value: group, child: Text(group)),
              ],
              onChanged: (value) => setState(() => _bloodGroup = value),
            ),
            const SizedBox(height: 24),

            Text('Medical Notes', style: AppTypography.darkTitleSmall),
            const SizedBox(height: 4),
            Text(
              'Allergies, conditions, medications, or anything a first responder should know.',
              style: AppTypography.darkBodySmall,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              maxLines: 5,
              decoration: const InputDecoration(hintText: 'e.g. Penicillin allergy, Type 1 diabetic'),
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: AppColors.primaryDeepBlue,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('SAVE'),
            ),
          ],
        ).animate().fadeIn(duration: motionDuration(context, AppDurations.pageTransition)).slideY(begin: 0.1, end: 0),
      ),
    );
  }
}
