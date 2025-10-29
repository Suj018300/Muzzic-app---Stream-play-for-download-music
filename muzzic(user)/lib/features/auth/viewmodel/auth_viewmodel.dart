import 'package:client/core/providers/current_user_notifier.dart';
import 'package:client/core/models/user_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../repositories/auth_local_repository.dart';
import '../repositories/auth_remote_repository.dart';

part 'auth_viewmodel.g.dart';

@riverpod
class AuthViewmodel extends _$AuthViewmodel {
  late AuthRemoteRepository _authRemoteRepository;
  late AuthLocalRepository _authLocalRepository;
  late CurrentUserNotifier _currentUserNotifier;

  @override
  AsyncValue<UserModel>? build() {
    _authRemoteRepository = ref.watch(authRemoteRepositoryProvider);
    _authLocalRepository = ref.watch(authLocalRepositoryProvider);
    _currentUserNotifier = ref.watch(currentUserNotifierProvider.notifier);
    return null;
  }

  Future<void>initSharedPreferences() async {
    await _authLocalRepository.init();
  }

  Future<void> signUpUser ({
    required String name,
    required String email,
    required String password,
  }) async {
    state =  const AsyncLoading();
    final res = await _authRemoteRepository.signup(
      name: name, 
      email: email, 
      password: password
    );

    final val = switch (res) {
      Left(value: final l) => state =  AsyncError(l.message, StackTrace.current),
      Right(value: final r) => state = AsyncData(r),
    };
    print(val);
  }

  Future<void> logInUser ({
    required String email,
    required String password,
  }) async {
    state =  const AsyncLoading();
    final res = await _authRemoteRepository.login(
      email: email, 
      password: password
    );

    final val = switch (res) {
      Left(value: final l) => state =  AsyncError(l.message, StackTrace.current),
      Right(value: final r) => _loginSuccess(r),
    };
    print(val);
  }

  AsyncValue<UserModel>? _loginSuccess(UserModel user) {
    _authLocalRepository.setToken(user.token);
    _currentUserNotifier.addUser(user);
    return state = AsyncData(user);
  }

  Future<UserModel?> getDate() async {
    state = const AsyncValue.loading();
    final token = await _authLocalRepository.getToken();
    if (token != null) {
      final res = await _authRemoteRepository.getCurrentUserData(token);
      final val = switch(res){
        Left(value: final l) => state = AsyncError(l.message, StackTrace.current),
        Right(value: final r) => _getDataSuccess(r),
      };
      return val.value;
    }
    return null;
  }

  AsyncValue<UserModel> _getDataSuccess(UserModel user) {
    _currentUserNotifier.addUser(user);
    return state = AsyncData(user);
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();

    final googleSignIn = GoogleSignIn(
      serverClientId: dotenv.env["WEB_CLIENT_ID"],
      scopes: ['email','profile']
    );

    try {
      final GoogleSignInAccount? account = await googleSignIn.signIn();
      if (account == null) {
        print("User cancelled sign in.");
        return;
      }

      final GoogleSignInAuthentication auth = await account.authentication;

      final idToken = auth.idToken;
      final accessToken = auth.accessToken;
      if (idToken == null) {
        print("No id token found");
        return;
      }

      final response = await _authRemoteRepository.loginWithGoogle(idToken: idToken);
      switch (response) {
        case Left(value: final failure):
          state = AsyncError(failure.message, StackTrace.current);
          break;
        case Right(value: final user):
          await _authLocalRepository.init();
          _authLocalRepository.setToken(user.token);
          _currentUserNotifier.addUser(user);
          state = AsyncData(user);
          break;
      };
    } catch(e) {
      print("Google sign in error: $e");
      return;
    }
  }

  Future<void> logOut() async {
    await _authLocalRepository.init();
    _authLocalRepository.setToken(null);
    _currentUserNotifier.addUser(null);
  }
}
