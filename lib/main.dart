import 'package:flutter/material.dart';
import 'package:like/like.dart';
import 'package:like_docs/app.dart';
import 'package:like_docs/like_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LikeService.init(config: LikeConfig());
  runApp(LikeApp(child: const LikeExampleApp()));
}
