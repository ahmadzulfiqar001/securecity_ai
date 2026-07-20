/// Lightweight Either-like result type for repository writes — mirrors the
/// shape of `mobile/lib/core/errors/failures.dart`'s `Result`, trimmed down
/// since the dashboard doesn't need the full typed-failure hierarchy (just
/// success/failure with a message).
sealed class Result<T> {
  const Result();

  void fold({
    required void Function(T value) onSuccess,
    required void Function(String message) onError,
  }) {
    switch (this) {
      case Success<T>(value: final v):
        onSuccess(v);
      case Error<T>(message: final m):
        onError(m);
    }
  }
}

final class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);
}

final class Error<T> extends Result<T> {
  final String message;
  const Error(this.message);
}
