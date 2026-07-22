import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/cards/glass_card.dart';
import '../../../../core/entities/emergency_contact_entity.dart';

/// Quick-glance summary of the user's emergency contacts, with a shortcut
/// into the full management screen (`features/emergency_contacts`).
class EmergencyContactsQuickCard extends StatelessWidget {
  const EmergencyContactsQuickCard({
    super.key,
    required this.contacts,
    required this.onTap,
  });

  final List<EmergencyContactEntity> contacts;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final names = contacts.take(2).map((c) => c.name).join(', ');
    final subtitle = contacts.isEmpty
        ? 'Add contacts to notify when you trigger an SOS.'
        : contacts.length > 2
            ? '$names +${contacts.length - 2} more'
            : names;

    return Semantics(
      button: true,
      label: 'Emergency contacts: ${contacts.length}. $subtitle',
      child: GlassCard(
        onTap: onTap,
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.glassCyan10,
              child: Icon(
                contacts.isEmpty ? Icons.person_add_alt_outlined : Icons.contact_phone_outlined,
                color: AppColors.accentCyan,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contacts.isEmpty ? 'No Emergency Contacts' : 'Emergency Contacts (${contacts.length})',
                    style: AppTypography.darkTitleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.darkBodySmall,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.darkTextSecondary),
          ],
        ),
      ),
    );
  }
}
