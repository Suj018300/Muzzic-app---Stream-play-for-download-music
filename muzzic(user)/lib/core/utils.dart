import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';

String rgbToHex(Color color) {
  final r = ((color.r * 255).round() & 0xff).toRadixString(16).padLeft(2, '0');
  final g = ((color.g * 255).round() & 0xff).toRadixString(16).padLeft(2, '0');
  final b = ((color.b * 255).round() & 0xff).toRadixString(16).padLeft(2, '0');

  return '$r$g$b';
}

Color hexToRgb(String hex) {
  return Color(int.parse(hex, radix: 16) + 0xFF000000);
}

void showSnackBar (BuildContext context, String content) {
  ScaffoldMessenger.of(context)
  ..hideCurrentMaterialBanner()
  ..showSnackBar(SnackBar(
    content: Text(content.toString())
  )
  );
}

class AppBanner {
  static void show(
      BuildContext context, {
        required String title,
        required String message,
        required ContentType contentType,
        bool inMaterialBanner = true,
        Duration duration = const Duration(seconds: 3),
      }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          elevation: 0,
          backgroundColor: Colors.transparent,
          duration: const Duration(seconds: 5),
          // animation: Animation(),
          content: AwesomeSnackbarContent(
            title: title.toString(),
            message: message.toString(),
            contentType: contentType,
            inMaterialBanner: inMaterialBanner,
          ),
          // actions: const [SizedBox.shrink()],
        ),
      );
  }
}

class AppBanner2 {
static void show(
    BuildContext context, {
      required String title,
      required String message,
      required ContentType contentType,
      bool inMaterialBanner = true,
      Duration duration = const Duration(seconds: 5),
    }
    ) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  
  entry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: MaterialBanner(
              /// need to set following properties for best effect of awesome_snackbar_content
              elevation: 0,
              backgroundColor: Colors.transparent,
              forceActionsBelow: true,
              content: AwesomeSnackbarContent(
                title: title.toString(),
                message: message.toString(),
                /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
                contentType: contentType,
                // to configure for material banner
                inMaterialBanner: inMaterialBanner,
              ),
              actions: const [SizedBox.shrink()],
            ),
        );
      }
  );
  overlay.insert(entry);
  
  Future.delayed(duration, () {
    entry.remove();
  } );
}
}




Future<File?> pickImage() async {
  try {
    final filePcikerRes = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if(filePcikerRes != null) {
      return File(filePcikerRes.files.first.xFile.path);
    }
    return null;

  } catch (e) {
    return null;
  }
}

Future<File?> pickAudio() async {
  try {
    final filePcikerRes = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );

    if(filePcikerRes != null) {
      return File(filePcikerRes.files.first.xFile.path);
    }
    return null;

  } catch (e) {
    return null;
  }
}