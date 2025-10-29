import 'dart:convert';

import 'package:client/core/constants/server_constants.dart';
import 'package:client/core/failure/failure.dart';
import 'package:client/core/models/user_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_remote_repository.g.dart';

@riverpod
AuthRemoteRepository authRemoteRepository(Ref ref) {
  return AuthRemoteRepository();
}

class AuthRemoteRepository {

  Future<Either<AppFailure, UserModel>> signup({
    required String name,
    required String email,
    required String password
  }) async {

    try {
      final response = await http.post(
      Uri.parse(
        '${ServerConstants.serverURL}/auth/signup'
      ),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(
        {
          "name": name,
          "email": email,
          "password": password
        },
      ),
    );

    final resBodyMap = jsonDecode(response.body) as Map<String , dynamic>;

    if (response.statusCode != 201) {

      return Left(AppFailure(resBodyMap['detail']));
    }

    return  Right(
      UserModel.fromMap(resBodyMap)
    );

    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
    
  }

  Future<Either<AppFailure, UserModel>> login({
    required String email,
    required String password
  }) async {

    try{
      final response = await http.post(
      Uri.parse(
        '${ServerConstants.serverURL}/auth/login'
      ),

      headers: {
        'Content-Type': 'application/json'
      },

      body: jsonEncode(
        {
          "email": email,
          "password": password
        }
      )
    );

    final resBodyMap = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      return Left(AppFailure(resBodyMap['detail']));
    }
    return Right(UserModel.fromMap(resBodyMap['user']).copyWith(
      token : resBodyMap['token']
    ));
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }


  Future<Either<AppFailure, UserModel>> getCurrentUserData(
    String token
    ) async {
    try{
      final response = await http.get(
        Uri.parse('${ServerConstants.serverURL}/auth/'),

        headers: {
          'Content-Type' : 'application/json',
          'x-auth-token' : token,
        }
      );

      final resBodyMap = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode != 200) {
        return Left(AppFailure(resBodyMap['detail']));
      }
      return Right(UserModel.fromMap(resBodyMap).copyWith(
          token: token
        ),
      );

    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  Future<Either<AppFailure, UserModel>> loginWithGoogle({
    required String idToken,
  }) async {
    try{
      final response = await http.post(
          Uri.parse("${ServerConstants.serverURL}/auth/google_sign"),
        headers: {
            "Content-Type": "application/json",
        },
        body: jsonEncode({
          "id_token": idToken
        })
      );

      final resBody = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode != 200) {
        return Left(AppFailure(resBody['detail']));
      }

      return Right(UserModel.fromMap({
        'name': resBody['user']['name'],
        'email': resBody['user']['email'],
        'id': resBody['user']['id'].toString(),
        'token': resBody['token'],
        'favorites': [], // empty for now
      }));

    } catch(e) {
      return Left(AppFailure(e.toString()));
    }
  }

}