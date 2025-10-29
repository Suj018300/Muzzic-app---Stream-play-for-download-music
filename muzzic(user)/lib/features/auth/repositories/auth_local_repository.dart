import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'auth_local_repository.g.dart';

@Riverpod(keepAlive: true)
AuthLocalRepository authLocalRepository(Ref ref) {
  return AuthLocalRepository();
}

class AuthLocalRepository {
  late SharedPreferences _sharedPreferences;

  Future<void> init() async {
    _sharedPreferences = await SharedPreferences.getInstance();
  }

  Future<void> setToken (String? token) async {
    await init();
    if (token != null) {
      _sharedPreferences.setString('x_auth_token', token);
    } else {
    _sharedPreferences.remove('x_auth_token');
    }
  }

  Future<String?> getToken() async {
    await init();
    return _sharedPreferences.getString('x_auth_token');
  }
}