import 'package:flutter/material.dart';
import 'video_upload_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hotsum Videos',
      theme: ThemeData(
        primarySwatch: const MaterialColor(0xffdbcf, <int, Color>{
          50: Color.fromARGB(255, 44, 72, 94),
          100: Color.fromARGB(255, 44, 72, 94),
          200: Color.fromARGB(255, 44, 72, 94),
          300: Color.fromARGB(255, 44, 72, 94),
          400: Color.fromARGB(255, 44, 72, 94),
          500: Color.fromARGB(255, 44, 72, 94),
          600: Color.fromARGB(255, 44, 72, 94),
          700: Color.fromARGB(255, 44, 72, 94),
          800: Color.fromARGB(255, 44, 72, 94),
          900: Color.fromARGB(255, 44, 72, 94),
        }),
      ),
      home: VideoUploadPage(),
    );
  }
}
