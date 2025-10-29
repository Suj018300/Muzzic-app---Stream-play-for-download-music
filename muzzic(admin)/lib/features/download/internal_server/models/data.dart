import 'package:flutter/foundation.dart';

class AudioFormat {
  final String ext;
  final String url;
  final double? fileSizeMb;
  final String formatId;

  const AudioFormat({
    required this.ext,
    required this.url,
    this.fileSizeMb,
    required this.formatId
  });

  factory AudioFormat.fromJson(Map<String, dynamic> json) {
    return AudioFormat(
        ext: json['ext']?.toString() ?? 'mp3',
        url: json['url']?.toString() ?? '',
      formatId: json['format_id'] ?? '',
      fileSizeMb: json['filesize_mb'] != null ? double.tryParse(json['filesize_mb'].toString()) : null,
    );
  }
}

class DataModel {
  final String title;
  final List<AudioFormat> audioFormats;

  const DataModel({
    required this.title,
    required this.audioFormats
  });

  factory DataModel.fromJson (Map<String, dynamic> json) {
    final list = (json['audio_formats'] as List<dynamic>? ?? []);
    final formats = list.map((e) => AudioFormat.fromJson(e as Map<String, dynamic>)).toList();

    return DataModel(
      title: json['title']?.toString() ?? 'Unknown Title',
      audioFormats: formats
    );
  }
}