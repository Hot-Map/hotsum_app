import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'dart:io';
import 'dart:async';

class VideoSummaryPage extends StatefulWidget {
  final String filePath;

  VideoSummaryPage({required this.filePath});

  @override
  _VideoSummaryPageState createState() => _VideoSummaryPageState();
}

class _VideoSummaryPageState extends State<VideoSummaryPage> {
  late VideoPlayerController _controller;
  late double _currentSliderValue = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.filePath))
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
        _updateSliderValue();
      });
  }

  void _updateSliderValue() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _currentSliderValue = _controller.value.position.inSeconds.toDouble();
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
    _timer?.cancel();
  }

  Future<void> _saveVideoToGallery(String filePath) async {
    var status = await Permission.photos.status;

    if (!status.isGranted) {
      status = await Permission.photos.request();
    }

    if (status.isPermanentlyDenied) {
      print('Permission is permanently denied, we cannot request permissions.');
      openAppSettings();
      return;
    }

    if (status.isGranted) {
      GallerySaver.saveVideo(filePath).then((bool? success) {
        setState(() {
          print('Video is saved');
        });
      });
    } else {
      print('Permission denied. Unable to save video to gallery.');
    }
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
        title: Text('Summary',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        backgroundColor: Color.fromARGB(255, 44, 72, 94),
      ),
      body: Container(
        color: Color.fromARGB(255, 192, 214, 230),
        child: Column(
          //mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(height: screenSize.height * 0.10),
            if (_controller.value.isInitialized)
              Stack(
                alignment: Alignment.center,
                children: [
                  AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  ),
                  FloatingActionButton(
                    child: Icon(
                      _controller.value.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                    ),
                    onPressed: () {
                      setState(() {
                        _controller.value.isPlaying
                            ? _controller.pause()
                            : _controller.play();
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
              max: _controller.value.duration.inSeconds.toDouble(),
              onChanged: (double value) {
                setState(() {
                  _currentSliderValue = value;
                  _controller.seekTo(Duration(seconds: value.toInt()));
                });
              },
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Container(
            width: 70,
            height: 70,
            child: FloatingActionButton(
              onPressed: () async {
                await _saveVideoToGallery(widget.filePath);
                showCupertinoDialog(
                  context: context,
                  builder: (BuildContext context) => CupertinoAlertDialog(
                    title: Text("Done!"),
                    content: Text("Summary saved to the gallery"),
                    actions: <Widget>[
                      CupertinoDialogAction(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        child: Text(
                          'OK',
                          selectionColor: Colors.black,
                        ),
                      ),
                    ],
                  ),
                );
              },
              child: Icon(Icons.save, size: 35),
              heroTag: null,
            ),
          ),
          SizedBox(width: 10),
          Container(
            width: 70,
            height: 70,
            child: FloatingActionButton(
              onPressed: () {
                showCupertinoDialog(
                  context: context,
                  builder: (BuildContext context) => CupertinoAlertDialog(
                    title: Text("Discard"),
                    content: Text("Summary discarded"),
                    actions: <Widget>[
                      CupertinoDialogAction(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        child: Text(
                          'OK',
                        ),
                      ),
                    ],
                  ),
                );
              },
              child: Icon(Icons.delete, size: 35),
              heroTag: null,
            ),
          ),
        ],
      ),
    );
  }
}
