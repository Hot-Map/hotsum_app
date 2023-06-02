import 'dart:io';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'video_summary_page.dart';

class VideoUploadPage extends StatefulWidget {
  @override
  _VideoUploadPageState createState() => _VideoUploadPageState();
}

class _VideoUploadPageState extends State<VideoUploadPage> {
  File? _videoFile;
  bool _isUploading = false;
  double _sliderValue = 1;
  bool _isAudioIncluded = false;
  VideoPlayerController? _videoPlayerController;
  double _currentSliderValue = 0.0;
  Timer? _timer; // new timer

  Future<void> _pickVideo() async {
    var status = await Permission.photos.status;
    if (!status.isGranted) {
      status = await Permission.photos.request();
    }

    if (status.isDenied) {
      print('Permission denied. Unable to pick video.');
      return;
    }

    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.video);

    if (result != null) {
      _videoFile = File(result.files.single.path!);
      _videoPlayerController = VideoPlayerController.file(_videoFile!)
        ..initialize().then((_) {
          setState(() {});
          _updateSliderValue();
        });
    } else {
      print("User cancelled the picker");
    }
  }

  void _updateSliderValue() {
    if (_videoPlayerController!.value.isPlaying) {
      _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
        setState(() {
          _currentSliderValue =
              _videoPlayerController!.value.position.inSeconds.toDouble();
        });
      });
    } else {
      _timer?.cancel();
    }
  }

  Future<String> _downloadVideo(String videoUrl) async {
    var dio = Dio();

    var dir = (await getTemporaryDirectory()).path;
    var split = videoUrl.split("/");
    var fileName = split[split.length - 1];

    if (!fileName.contains('.')) {
      fileName += '.mp4';
    }

    var path = "$dir/$fileName";

    await dio.download(videoUrl, path);

    return path;
  }

  Future<void> _uploadVideo() async {
    if (_videoFile == null) return;

    var dio = Dio();

    var formData = FormData.fromMap({
      "file": await MultipartFile.fromFile(_videoFile!.path),
      "proportion": _sliderValue / 100,
      "audio": _isAudioIncluded ? 1 : 0,
    });

    setState(() {
      _isUploading = true;
    });

    var url = "http://20.224.23.172:5001";
    var response = await dio.post("$url/upload", data: formData);

    if (response.statusCode == 200) {
      print("Video upload successful");

      var filePath =
          await _downloadVideo(url + "/download/" + response.data.toString());
      print("Video downloaded at path: $filePath");

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoSummaryPage(filePath: filePath),
        ),
      );
    } else {
      print("Video upload failed");
    }

    setState(() {
      _isUploading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    var screenSize = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hotsum',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 44, 72, 94),
      ),
      body: Container(
        color: const Color.fromARGB(255, 192, 214, 230),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              if (_videoPlayerController == null)
                const Icon(Icons.video_call, size: 150)
              else
                Stack(
                  alignment: Alignment.center,
                  children: [
                    AspectRatio(
                      aspectRatio: _videoPlayerController!.value.aspectRatio,
                      child: VideoPlayer(_videoPlayerController!),
                    ),
                    FloatingActionButton(
                      backgroundColor: !_videoPlayerController!.value.isPlaying
                          ? const Color.fromARGB(255, 44, 72, 94)
                          : Colors.transparent,
                      elevation: 0.0,
                      child: !_videoPlayerController!.value.isPlaying
                          ? const Icon(
                              Icons.play_arrow,
                            )
                          : const Opacity(opacity: 0.0),
                      onPressed: () {
                        setState(() {
                          _videoPlayerController!.value.isPlaying
                              ? _videoPlayerController!.pause()
                              : _videoPlayerController!.play();
                          _updateSliderValue();
                        });
                      },
                    ),
                  ],
                ),
              Slider(
                activeColor: Colors.black,
                inactiveColor: Colors.grey,
                value: _currentSliderValue,
                min: 0.0,
                max: _videoPlayerController != null
                    ? _videoPlayerController!.value.duration.inSeconds
                        .toDouble()
                    : 0.0,
                onChanged: (double value) {
                  setState(() {
                    _currentSliderValue = value;
                    _videoPlayerController!
                        .seekTo(Duration(seconds: value.toInt()));
                  });
                },
              ),
              const SizedBox(height: 0),
              Container(
                width: screenSize.width * 0.45,
                padding: const EdgeInsets.all(10),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(20),
                    primary: const Color.fromARGB(255, 44, 72, 94),
                  ),
                  child: const Text("Pick Video",
                      style: TextStyle(fontSize: 16, color: Colors.white)),
                  onPressed: _pickVideo,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: screenSize.width * 0.9,
                padding: const EdgeInsets.all(10),
                child: Text('Keep ${_sliderValue.toInt()}%',
                    style: const TextStyle(fontSize: 24)),
              ),
              Container(
                width: screenSize.width * 0.95,
                height: screenSize.width * 0.15,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: CupertinoSlider(
                  value: _sliderValue,
                  min: 1,
                  max: 100,
                  divisions: 99,
                  activeColor: const Color.fromARGB(255, 44, 72, 94),
                  onChanged: (double value) {
                    setState(() {
                      _sliderValue = value;
                    });
                  },
                ),
              ),
              const SizedBox(height: 0),
              Container(
                width: screenSize.width * 0.95,
                height: screenSize.width * 0.15,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Include Audio", style: TextStyle(fontSize: 24)),
                    CupertinoSwitch(
                      activeColor: const Color.fromARGB(255, 44, 72, 94),
                      value: _isAudioIncluded,
                      onChanged: (bool value) {
                        setState(() {
                          _isAudioIncluded = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: screenSize.width * 0.95,
                padding: const EdgeInsets.all(0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(20),
                    primary: const Color.fromARGB(255, 44, 72, 94),
                  ),
                  child: Text(_isUploading ? "Summarizing..." : "Summarize!",
                      style:
                          const TextStyle(fontSize: 24, color: Colors.white)),
                  onPressed: _isUploading ? null : _uploadVideo,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _timer?.cancel();
    _videoPlayerController?.dispose();
  }
}
