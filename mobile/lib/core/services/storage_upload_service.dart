import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

/// Thin wrapper around Firebase Storage uploads, shared by every feature
/// that attaches evidence/media (incident reports, SOS audio, profile
/// photos) so upload + download-URL retrieval isn't duplicated per feature.
class StorageUploadService {
  final FirebaseStorage _storage;

  StorageUploadService(this._storage);

  /// Uploads [file] to [path] (a full Storage path, e.g.
  /// `incidents/media/{uid}/{incidentId}/{fileName}` - see
  /// `storage.rules` for the paths each feature is allowed to write to)
  /// and returns its public download URL.
  Future<String> uploadFile({
    required String path,
    required File file,
    String? contentType,
  }) async {
    final ref = _storage.ref(path);
    await ref.putFile(
      file,
      contentType != null ? SettableMetadata(contentType: contentType) : null,
    );
    return ref.getDownloadURL();
  }
}
