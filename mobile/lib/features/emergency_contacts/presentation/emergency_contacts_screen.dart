import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/utils/motion.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/cards/glass_card.dart';
import '../../../shared/dialogs/app_snackbar.dart';
import '../../../shared/dialogs/confirmation_dialog.dart';
import '../../../shared/inputs/app_text_field.dart';
import '../../../shared/widgets/avatar.dart';
import '../../../core/entities/emergency_contact_entity.dart';
import 'providers/emergency_contacts_providers.dart';

class EmergencyContactsScreen extends ConsumerWidget {
  const EmergencyContactsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactsAsync = ref.watch(emergencyContactsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Trusted Contacts')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accentCyan,
        onPressed: () => _showContactDialog(context, ref),
        child: const Icon(Icons.add, color: AppColors.primaryDeepBlue),
      ),
      body: contactsAsync.when(
        loading: () => const SkeletonListLoader(itemCount: 3),
        error: (error, _) => ErrorState(
          message: "Couldn't load your trusted contacts right now.",
          onRetry: () => ref.invalidate(emergencyContactsStreamProvider),
        ),
        data: (contacts) {
          if (contacts.isEmpty) {
            return EmptyState(
              icon: Icons.contact_phone_outlined,
              message: 'No emergency contacts yet.\nAdd the people who should be notified when you trigger an SOS.',
              actionLabel: 'Add Contact',
              onAction: () => _showContactDialog(context, ref),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              final contact = contacts[index];
              return GlassCard(
                margin: const EdgeInsets.only(bottom: 16),
                padding: EdgeInsets.zero,
                child: ListTile(
                  leading: Avatar(
                    initials: contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
                    backgroundColor: AppColors.glassCyan10,
                  ),
                  title: Text(contact.name),
                  subtitle: Text('${contact.relationship} · ${contact.phone}'),
                  trailing: PopupMenuButton<String>(
                    tooltip: 'More actions for ${contact.name}',
                    onSelected: (action) {
                      if (action == 'edit') {
                        _showContactDialog(context, ref, existing: contact);
                      } else if (action == 'delete') {
                        _deleteContact(context, ref, contact.id, contact.name);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ),
              );
            },
          ).animate().fadeIn(duration: motionDuration(context, AppDurations.pageTransition)).slideY(begin: 0.1, end: 0);
        },
      ),
    );
  }

  Future<void> _deleteContact(BuildContext context, WidgetRef ref, String contactId, String name) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete Contact',
      message: 'Remove $name from your emergency contacts? They will no longer be notified when you trigger an SOS.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (!confirmed) return;

    final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
    if (uid == null) return;

    final result = await ref.read(emergencyContactsRepositoryProvider).deleteContact(uid, contactId);
    if (!context.mounted) return;

    result.fold(
      onSuccess: (_) => AppSnackbar.showSuccess(context, '$name removed from trusted contacts.'),
      onError: (failure) => AppSnackbar.showError(context, failure.message),
    );
  }

  Future<void> _showContactDialog(
    BuildContext context,
    WidgetRef ref, {
    EmergencyContactEntity? existing,
  }) async {
    final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
    if (uid == null) return;

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: existing?.name);
    final phoneController = TextEditingController(text: existing?.phone);
    final relationshipController = TextEditingController(text: existing?.relationship);

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(existing == null ? 'Add Emergency Contact' : 'Edit Emergency Contact'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                label: 'Full Name',
                controller: nameController,
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Phone Number',
                controller: phoneController,
                keyboardType: TextInputType.phone,
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Relationship',
                controller: relationshipController,
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(dialogContext).pop(true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved != true) return;

    final contact = EmergencyContactEntity(
      id: existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: nameController.text.trim(),
      phone: phoneController.text.trim(),
      relationship: relationshipController.text.trim(),
    );

    final repository = ref.read(emergencyContactsRepositoryProvider);
    final result = existing == null
        ? await repository.addContact(uid, contact)
        : await repository.updateContact(uid, contact);

    if (context.mounted) {
      result.fold(
        onSuccess: (_) {},
        onError: (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(failure.message), backgroundColor: AppColors.emergencyRed),
          );
        },
      );
    }
  }
}
