import '../main.dart' show MyApp;
import 'package:flutter/material.dart';
import 'app_ar.dart';
import 'app_en.dart';

String tr(BuildContext context, String key) {
  final lang = MyApp.of(context)?.language ?? 'ar';
  if (lang == 'en') {
    return enStrings[key] ?? arStrings[key] ?? key;
  }
  return arStrings[key] ?? key;
}