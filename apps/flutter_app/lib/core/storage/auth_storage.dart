import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

class AuthStorage {
  const AuthStorage(this._storage);

  final FlutterSecureStorage _storage;

  Future<void> saveToken(String token) {
    return _storage.write(key: AppConstants.authTokenKey, value: token);
  }

  Future<String?> readToken() {
    return _storage.read(key: AppConstants.authTokenKey);
  }

  Future<void> clear() {
    return _storage.delete(key: AppConstants.authTokenKey);
  }
}
