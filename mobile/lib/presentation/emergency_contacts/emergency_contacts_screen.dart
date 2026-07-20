import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/emergency_contacts_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/emergency_contacts_repository.dart';
import '../widgets/app_state_view.dart';
import '../widgets/glass_card.dart';

final emergencyContactsRepositoryProvider = Provider<EmergencyContactsRepository>((ref) {
  return EmergencyContactsRepositoryImpl(ref.watch(firestoreProvider));
});

final emergencyContactsStreamProvider =
    StreamProvider.autoDispose<List<EmergencyContactEntity>>((ref) {
  final uid = ref.watch(firebaseAuthProvider).currentUser?.uid;
  if (uid == null) return const Stream.empty();
  return ref.watch(emergencyContactsRepositoryProvider).watchContacts(uid);
});

class EmergencyContactsScreen extends ConsumerWidget {
  const EmergencyContactsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactsAsync = ref.watch(emergencyContactsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Contacts')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accentCyan,
        onPressed: () => _showContactDialog(context, ref),
        child: const Icon(Icons.add, color: AppColors.primaryDeepBlue),
      ),
      body: contactsAsync.when(
        loading: () => const AppLoadingView(),
        error: (error, _) => AppErrorView(message: 'Failed to load contacts: $error'),
        data: (contacts) {
          if (contacts.isEmpty) {
            return AppEmptyView(
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
                  leading: CircleAvatar(
                    backgroundColor: AppColors.glassCyan10,
                    child: Text(
                      contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
                      style: const TextStyle(color: AppColors.accentCyan, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(contact.name),
                  subtitle: Text('${contact.relationship} · ${contact.phone}'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (action) {
                      if (action == 'edit') {
                        _showContactDialog(context, ref, existing: contact);
                      } else if (action == 'delete') {
                        _deleteContact(context, ref, contact.id);
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
          );
        },
      ),
    );
  }

  Future<void> _deleteContact(BuildContext context, WidgetRef ref, String contactId) async {
    final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
    if (uid == null) return;
    await ref.read(emergencyContactsRepositoryProvider).deleteContact(uid, contactId);
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
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: relationshipController,
                decoration: const InputDecoration(labelText: 'Relationship'),
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
