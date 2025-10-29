import 'dart:io';
import 'package:client/core/constants/server_constants.dart';
import 'package:client/core/utils.dart';
import 'package:client/features/download/internal_server/models/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:permission_handler/permission_handler.dart';

import '../view/video_player.dart';
// import '../../external_server/view/video_player.dart';

class AudioFormats extends StatefulWidget {
  final String audioURL;

  const AudioFormats({
    super.key,
    required this.audioURL
  });

  @override
  State<AudioFormats> createState() => _AudioFormatsState();
}

class _AudioFormatsState extends State<AudioFormats> {
  bool isLoading = false;
  double progress = 0.0;

  Future<DataModel> fetchFormats() async {
    final response = await http.get(
      Uri.parse('${ServerConstants.serverURL}/download/formats/audio?url=${widget.audioURL}')
    );
    
    if (response.statusCode == 200) {
      return DataModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception("Failed to fetch the formats: ${response.statusCode}");
    }
  }

  Future<String> downloadAudio({
    required String audioUrl,
    required String title,
    required String ext,
  }) async {
    final response = await http.get(
        Uri.parse('${ServerConstants.serverURL}/download/audio?url=$audioUrl')
    );

    if (response.statusCode != 200) {
      throw Exception("Download failed with status ${response.statusCode}");
    }

    final safeTitle = title.replaceAll(RegExp(r'[\/\\:*?"<>|]'), '_');
    final fileName = "$safeTitle.$ext";

    Directory dir;
    if (Platform.isAndroid) {
      dir = Directory('/storage/emulator/0/Download');
      if (!await dir.exists()) {
        dir = await getApplicationDocumentsDirectory();
      }
    } else {
      dir = await getApplicationDocumentsDirectory();
    }
    final filePath = '${dir.path}$fileName';
    final file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);

    return filePath;
  }

  Future<String> getFolder(String fileName) async {
    Directory? dir;
    try {
      dir = Directory('/storage/emulator/0/Download');
      if (await dir.exists()) dir = (await getExternalStorageDirectory());
    } catch(error) {
      showSnackBar(context, "Error for folder: $error");
    }
    return '${dir?.path}$fileName';
  }

  void download(String url, String formats, String title) async {
    String path = await getFolder(url);
    var result = await Permission.storage.request().then((value) {
      if (value.isGranted) {
        try {
          FileDownloader.downloadFile(
              url: url,
            name: title,
            downloadDestination: DownloadDestinations.publicDownloads,
            onProgress: (context, value) {
                isLoading == true;
                setState(() {
                  progress = value;
                });
            },
            onDownloadCompleted: (complete) {
                setState(() {
                  isLoading = false;
                });
                AppBanner2.show(
                    context,
                    title: "Audio Downloaded",
                    message: "Your select file is downloaded successfully and stored in downloads file",
                    contentType: ContentType.success,
                  inMaterialBanner: false
                );
            },
            onDownloadError: (eror) {
                setState(() {
                  isLoading = false;
                });
                showSnackBar(context, "Download failed: $eror");
            }
          );
        } catch(error) {
          showSnackBar(context, 'Download is failed: $error');
        }
      }
      else if (value.isDenied) {
        showSnackBar(context, 'Storage access is denied, allow storage permission to continue download');
      }
      else {
        showSnackBar(context, 'Download Error');
      }
    }
    );
  }

  late Future<DataModel> futureStream;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    futureStream = fetchFormats();
    futureStream.then((data) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _formatShowBottomSheet(context, data, widget.audioURL);
      }
      );
    }).catchError((e) {
      debugPrint("Error fetching formats: $e");
    });
  }

void _formatShowBottomSheet (BuildContext context, DataModel data, String audioUrl) {
    AudioFormat? selectedFormat;
    bool downloading = false;

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) {
            return StatefulBuilder(
              builder: (content, setModelState) {
                return Padding(
                  padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom + 12,
                      left: 12,
                      right: 12,
                      top: 12
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        data.title,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const Divider(),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
                        child: ListView.separated(
                          separatorBuilder: (_, _) => const Divider(height: 0),
                          itemCount: data.audioFormats.length,
                          itemBuilder: (context, index) {
                            final format = data.audioFormats[index];
                            final isSelected = selectedFormat == format;
                            return ListTile(
                              leading: IconButton(
                                  onPressed: () {
                                    Navigator.push(context, MaterialPageRoute(
                                        builder: (context) =>
                                            VideoPlayer(url: audioUrl)
                                    )
                                    );
                                  },
                                  icon: const Icon(Icons.play_arrow)
                              ),
                              title: Text(format.ext.toUpperCase()),
                              subtitle: isSelected
                                  ? const Icon(Icons.check_circle)
                                  : const Icon(Icons.circle_outlined),
                              onTap: () {
                                setModelState(() =>
                                selectedFormat = format
                                );
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12,),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: downloading ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(),
                          ) : const Icon(Icons.download),
                          label: Text(downloading ? "Downloading..." : "Download selected format"),
                          onPressed: selectedFormat == null || downloading
                              ? null
                              : () async {
                            setModelState (() => downloading = true);
                            try {
                              final savePath = await downloadAudio(
                                audioUrl: audioUrl,
                                title: data.title,
                                ext: selectedFormat!.ext,
                              );
                              setState(() => downloading = false);
                              Navigator.pop(context);
                              AppBanner2.show(
                                  context,
                                  title: "Audio Downloaded",
                                  message: "Your select file is downloaded successfully and stored in downloads file",
                                  contentType: ContentType.success,
                                  inMaterialBanner: false
                              );
                            } catch(e) {
                              setState(() => downloading = false);
                              showSnackBar(context, "Download failed: $e");
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 8,)
                    ],
                  ),
                );
              },
            );
        }
    );
}


  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      )

      // SafeArea(
      //   minimum: const EdgeInsets.all(18),
      //   child: SingleChildScrollView(
      //     scrollDirection: Axis.vertical,
      //     child: Expanded(
      //       child: FutureBuilder(future: futureStream, builder: (context, snapshot) {
      //         if(snapshot.hasData) {
      //           return Column(
      //             spacing: 20,
      //             mainAxisAlignment: MainAxisAlignment.center,
      //             crossAxisAlignment: CrossAxisAlignment.center,
      //             children: [
      //               ListView.builder(
      //                   shrinkWrap: true,
      //                   physics: const NeverScrollableScrollPhysics(),
      //                   itemCount: snapshot.data!.audioFormats.length ,
      //                   itemBuilder: (context, index) {
      //                     return Card(
      //                       child: Padding(
      //                         padding: const EdgeInsets.all(8.0),
      //                         child: Row(
      //                           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      //                           children: [
      //                             Text.rich(
      //                                 TextSpan(text: snapshot.data?.audioFormats[index]['ext'],
      //                                   style: const TextStyle(
      //                                       fontSize: 16,
      //                                       fontWeight: FontWeight.w600
      //                                   ),
      //                                 )
      //                             ),
      //                             // const SizedBox(width: 12,),
      //                             Text.rich(
      //                                 TextSpan(text: snapshot.data?.audioFormats[index]['resolution'],
      //                                   style: const TextStyle(
      //                                       fontSize: 16,
      //                                       fontWeight: FontWeight.w600
      //                                   ),
      //                                 )
      //                             ),
      //                             IconButton(
      //                               onPressed: () {
      //                                 Navigator.push(
      //                                     context, MaterialPageRoute(
      //                                     builder: (context) => VideoPlayer(
      //                                         url: snapshot.data!.audioFormats[index]['url'])
      //                                 )
      //                                 );
      //                                 },
      //                               icon: const Icon(Icons.play_arrow),
      //                               iconSize: 22,
      //                             ),
      //                             IconButton(
      //                               onPressed: () async {
      //                                 downloadAudio(audioUrl: widget.audioURL);
      //                                 // download(
      //                                 //   snapshot.data!.audio_formats[index]['url'],
      //                                 //   snapshot.data!.audio_formats[index]['audio_formats'].toString() ,
      //                                 //   snapshot.data!.title,
      //                                 // );
      //                                 },
      //                               icon: const Icon(Icons.download),
      //                               iconSize: 22,
      //                             ),
      //                           ],
      //                         ),
      //                       ),
      //                     );
      //                   })
      //             ],
      //           );
      //         } else if (snapshot.hasError) {
      //           return ScaffoldMessenger(child: Text('Format builder has error'));
      //         }
      //         return const CircularProgressIndicator();
      //       }
      //       ),
      //     ),
      //   ),
      // ),
    );
  }

}

