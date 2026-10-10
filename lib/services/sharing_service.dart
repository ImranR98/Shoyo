import 'dart:async';

import 'package:flutter_sharing_intent/flutter_sharing_intent.dart';
import 'package:flutter_sharing_intent/model/sharing_file.dart';

abstract class SharingService {
  Stream<List<SharedFile>> get stream;
  Future<List<SharedFile>> initial();
  Future<void> reset();
}

class FlutterSharingService implements SharingService {
  @override
  Stream<List<SharedFile>> get stream =>
      FlutterSharingIntent.instance.getMediaStream();

  @override
  Future<List<SharedFile>> initial() =>
      FlutterSharingIntent.instance.getInitialSharing();

  @override
  Future<void> reset() async => FlutterSharingIntent.instance.reset();
}
