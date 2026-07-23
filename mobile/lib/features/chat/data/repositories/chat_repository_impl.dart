import 'package:firebase_ai/firebase_ai.dart';

import '../../../../core/errors/failures.dart';
import '../../../services/domain/entities/nearby_service_entity.dart';
import '../../domain/repositories/chat_repository.dart';

/// Talks to Gemini through Firebase AI Logic's Gemini Developer API
/// backend (`FirebaseAI.googleAI()`) - no raw API key in the client, no
/// billing account required (unlike the Vertex AI backend). Firebase App
/// Check (activated in main.dart) is what actually authorizes these calls.
class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl({required List<NearbyServiceEntity> nearbyServices})
      : _nearbyServices = nearbyServices;

  final List<NearbyServiceEntity> _nearbyServices;
  ChatSession? _session;

  ChatSession _ensureSession() {
    return _session ??= FirebaseAI.googleAI()
        .generativeModel(
          model: 'gemini-3.5-flash',
          systemInstruction: Content.system(_systemPrompt()),
        )
        .startChat();
  }

  String _systemPrompt() {
    final servicesSummary = _nearbyServices.isEmpty
        ? 'No nearby services data is available right now.'
        : _nearbyServices
            .take(15)
            .map((s) =>
                '- ${s.name} (${NearbyServiceType.label(s.type)}), ${s.address}'
                '${s.phone != null && s.phone!.isNotEmpty ? ', phone: ${s.phone}' : ''}')
            .join('\n');

    return '''
You are the SecureCity AI Safety Assistant, an in-app chatbot inside a citizen
safety app. You help with:
- General safety advice
- Emergency / first-aid guidance
- Crime-prevention questions
- Questions about nearby emergency services (police, hospitals, fire
  stations, shelters, pharmacies)

For any genuine, ongoing emergency, always remind the user to press the SOS
button in the app rather than relying only on this chat - you cannot dispatch
help yourself.

Keep answers concise and practical, suited to a mobile chat bubble (a few
short sentences, or a short numbered list) - not long essays.

Nearby services currently known to the app (use these for "nearest
hospital/police/..." questions - do not invent services that aren't listed):
$servicesSummary
''';
  }

  @override
  Future<Result<String>> sendMessage(String message) async {
    try {
      final response = await _ensureSession().sendMessage(Content.text(message));
      final text = response.text;
      if (text == null || text.trim().isEmpty) {
        return const Error(UnknownFailure(message: 'The assistant did not return a response.'));
      }
      return Success(text.trim());
    } catch (e) {
      return Error(UnknownFailure(
        message: 'Could not reach the AI assistant. Check your connection and try again.',
        cause: e,
      ));
    }
  }
}
