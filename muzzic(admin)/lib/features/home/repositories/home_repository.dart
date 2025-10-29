import 'dart:convert';
import 'dart:io';
import 'package:client/core/constants/server_constants.dart';
import 'package:client/core/failure/failure.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/song_model.dart';
part 'home_repository.g.dart';

@riverpod
HomeRepository homeRepository(Ref ref) {
  return HomeRepository();
}

/// This page is to initialize Future providers

class HomeRepository {
    Future<Either<AppFailure, String>> uploadSong({
    required File selectedAudio,
    required File selectedImage,
    required String songName,
    required String artist,
    required String hexCode,
    required String token,
  }) async {
      try {
        final request = http.MultipartRequest(
            'POST',
            Uri.parse('${ServerConstants.serverURL}/song/upload')
        );
        request..files.addAll(
          [
            await http.MultipartFile.fromPath('song', selectedAudio.path),
            await http.MultipartFile.fromPath('thumbnail', selectedImage.path),
          ],
        )

          ..fields.addAll(
            {
              'artist': artist, 
              'song_name': songName, 
              'hex_code': hexCode,
            },
          )
          ..headers.addAll({
            'x-auth-token': token
          });

        final res = await request.send();
        print(res);

        if (res.statusCode!=201) {
          return Left(AppFailure(await res.stream.bytesToString()));
        }
        return Right(await res.stream.bytesToString());
      } catch(e) {
        return Left(AppFailure(e.toString()));
      }
    }
    
    Future<Either<AppFailure, List<SongModel>>> getAllSongs({
      required String token,
    }) async {
      try {
        final res = await http.get(Uri.parse('${ServerConstants.serverURL}/song/list'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token,
        }
        );
          var resBodyMap = jsonDecode(res.body);

        if(res.statusCode != 200) {
          resBodyMap = resBodyMap as Map<String, dynamic>;
          return Left(AppFailure(resBodyMap['detail']));
        }
        resBodyMap = resBodyMap as List;

        List<SongModel> songs = [];

        for (final map in resBodyMap) {
          songs.add(SongModel.fromMap(map));
        }

        return Right(songs);
      } catch (e) {
        return Left(AppFailure(e.toString()));
      }
    }

    Future<Either<AppFailure, bool>> favSong({
      required String token,
      required String songId,
    }) async {
      try {
        final res = await http.post(Uri.parse('${ServerConstants.serverURL}/song/favorite'),
            headers: {
              'Content-Type': 'application/json',
              'x-auth-token': token,
            },
          body: jsonEncode(
            {
              "song_id": songId
            }
          )
        );
        var resBodyMap = jsonDecode(res.body);

        if(res.statusCode != 200) {
          resBodyMap = resBodyMap as Map<String, dynamic>;
          return Left(AppFailure(resBodyMap['detail']));
        }

        return Right(resBodyMap['message']);
      } catch (e) {
        return Left(AppFailure(e.toString()));
      }
    }

    Future<Either<AppFailure ,List<SongModel>>> getFavSongs({
      required String token,
    }) async {
      try {
        final res = await http.get(
          Uri.parse('${ServerConstants.serverURL}/song/list/favorite'),
          headers: {
            'Content-Type': 'application/json',
            'x-auth-token': token,
          },
        );
        var resBodyMap = jsonDecode(res.body);

        if (res.statusCode != 200) {
          resBodyMap = resBodyMap as Map<String, dynamic>;
          return Left(AppFailure(resBodyMap['detail']));
        }
        resBodyMap = resBodyMap as List;

        List<SongModel> songs = [];

        for (final map in resBodyMap) {
          songs.add(SongModel.fromMap(map['song']));
        }

        return Right(songs);
      } catch (e) {
        return Left(AppFailure(e.toString()));
      }
    }

    Future<List<SongModel>> getSongsList({
      required String token
    }) async {
      // print("✅ getSongsList CALLED with token: $token");
      final response = await http.get(
            Uri.parse('${ServerConstants.serverURL}/song/list'),
          headers: {
            'Content-Type': 'application/json',
            'x-auth-token': token
          }
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch songs');
      }

      final raw = response.body;
      if (raw == null || raw.isEmpty) {
        return []; // no recently played songs
      }
      // print("Raw body: $raw");

      final decoded = jsonDecode(raw) as List<dynamic>;
      // print("Decoded: $decoded");
      print("Type: ${decoded.runtimeType}");

      final songs = decoded.map((e) => SongModel.fromMap(e as Map<String, dynamic>)).toList();
      songs.sort((a, b) => (b.create_at ?? DateTime(0)).compareTo(a.create_at ?? DateTime(0)));
      return songs;
    }

    Future<List<SongModel>> getUserSongs({
      required String token
    }) async {
      final response = await http.get(
        Uri.parse('${ServerConstants.serverURL}/song/list'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token,
        }
      );

      final decode = jsonDecode(response.body) as List<dynamic>;
      if (decode == null || decode.isEmpty) {
        return []; // no recently played songs
      }
      final songs = decode.map((e) => SongModel.fromMap(e as Map<String, dynamic>)).toList();
      // songs.sort((a,b));
      return songs;
    }
    
    Future<Either<AppFailure, String>> editSong({
      File? selectedAudio,
      File? selectedImage,
      required String token,
      required String id,
      String? songName,
      String? artist,
      String? hexCode,
    }) async {
      try {
        var uri = Uri.parse('${ServerConstants.serverURL}/song/list/$id');
        final response = http.MultipartRequest(
          'PUT',
          uri
        );
        print('URI is runned');

        if (selectedAudio != null) {
          response.files.add(await http.MultipartFile.fromPath('song', selectedAudio.path));
        }
        if (selectedImage != null) {
          response.files.add(await http.MultipartFile.fromPath('thumbnail', selectedImage.path));
        }

        if (songName != null) response.fields['song_name'] = songName;
        if (artist != null) response.fields['artist'] = artist;
        if (hexCode != null) response.fields['hex_code'] = hexCode;

        response.headers['x-auth-token'] = token;

        final res = await response.send();

        final body = await res.stream.bytesToString();

        if (res.statusCode != 200) {
          return Left(AppFailure(body));
        }
        return Right(body);
      } catch (error) {
        return Left(AppFailure(error.toString()));
      }
    }

    Future<String> deleteSong({
      required String id,
      required String token,
    }) async {
      final response = await http.delete(
        Uri.parse('${ServerConstants.serverURL}/list/$id'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token
        },
      );

      if (response.statusCode != 200) {
        return "Failed to delete item: ${response.statusCode}";
      } else {
        return 'Successfully deleted the Song';
      }
    }

    Future<String> downloadAudio({
      required String audioUrl,
    }) async {
      final response = await http.get(
        Uri.parse('${ServerConstants.serverURL}/download/audio?url=$audioUrl')
      );

      if (response.statusCode == 200) {
        final dir = await getApplicationDocumentsDirectory();

        String? filename;
        final contentDisp = response.headers['content-disposition'];
        if (contentDisp != null && contentDisp.contains('filename=')) {
          filename = contentDisp.split('filename=')[1].replaceAll('"', '');
        } else {
          filename = "downloaded_audio.mp3";
        }

        final filePath = "${dir.path}/$filename";

        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        return filePath;
      } else {
        throw Exception('failed to download audio');
      }
    }

    Future<void> saveToDownloads({
      required String id,
      required String token,
    }) async {
      final response = await http.get(
        Uri.parse('${ServerConstants.serverURL}/song/list/$id'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token
        }
      );
      if(response.statusCode != 200) throw Exception('Failed to fetch the song: ${response.statusCode}');

      final res = jsonDecode(response.body);

      /// App storage access
      final dir = await getApplicationDocumentsDirectory();

      /// Audio download
      final audioPath = "${dir.path}/${res['id']}.mp3";
      await Dio().download(res['song_url'], audioPath);

      /// Thumbnail download
      final thumbnailPath = "${dir.path}/${res['id']}.jpg";
      await Dio().download(res['thumbnail_url'], thumbnailPath);

      final box = Hive.box<SongModel>('offlineSongs');
      final song = box.get(res['id']);

      if (song != null) {
        if (song.isDownload) {
          print("Song and thumbnail are downloaded ✅");
        } else {
          print("Song is not fully downloaded ❌");
        }
      }

      final downloadedSong = SongModel(
          id: res['id'],
          song_name: res['song_name'],
          artist: res['artist'],
          thumbnail_url: res['thumbnail_url'],
          song_url: res['song_url'],
          hex_code: res['hex_code'],
        localAudioPath: audioPath,
        localThumbnailPath: thumbnailPath
      );

      // final box = Hive.box<SongModel>('offlineSongs');
      await box.put(res['id'], downloadedSong);
    }
}