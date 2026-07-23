import '../../../../core/errors/failures.dart';

abstract class ChatRepository {
  /// Sends [message] to the AI safety assistant and returns its reply.
  /// Conversation history is kept internally between calls on the same
  /// repository instance (a fresh chat session per screen visit - see
  /// `chatRepositoryProvider`).
  Future<Result<String>> sendMessage(String message);
}
