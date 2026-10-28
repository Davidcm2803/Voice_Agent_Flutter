import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:voice_agent_flutter/core/config.dart';
import 'package:voice_agent_flutter/ui/chat/chat_screen.dart';
import 'package:voice_agent_flutter/ui/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  runApp(const AxelApp());
}

class AxelApp extends StatelessWidget {
  const AxelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const ChatScreen(),
    );
  }
}