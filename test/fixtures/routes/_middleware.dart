// Mock middleware file - should be skipped by route discovery
// ignore_for_file: unused_element

import 'package:dart_frog/dart_frog.dart';

Handler middleware(Handler handler) =>
    (context) async => handler(context);
