import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:record/record.dart';

typedef AudioDataCallback = void Function(Uint8List data);
typedef DoneCallback = void Function();
typedef ErrorCallback = void Function(dynamic error);

abstract interface class IAudioRecorder {
  Future<void> start();

  Future<void> pause();

  Future<void> resume();

  Future<String?> stop();

  Future<void> dispose();
}

class ParcoolAudioRecorder implements IAudioRecorder {
  final int sampleRate;
  final int numChannels;
  late final AudioRecorder record;
  final AudioDataCallback onData;
  final DoneCallback onDone;
  final ErrorCallback onError;
  final bool cancelOnError;

  File? fileForStream;

  ParcoolAudioRecorder({
    required this.sampleRate,
    required this.numChannels,
    required this.onData,
    required this.onDone,
    required this.onError,
    this.cancelOnError = true,
  }) {
    record = AudioRecorder();
  }

  ///
  /// 参考代码：
  // final Directory appDir = await getApplicationDocumentsDirectory();
  // final String filePath =
  //     '${appDir.path}/my_new_recording${DateTime.now().millisecondsSinceEpoch}.ogg';
  @override
  Future<void> start() async {
    if (await record.hasPermission()) {
      if (await record.isRecording()) {
        onError("Already recording.");
        return;
      }
      final stream = await record.startStream(
        RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: sampleRate,
          numChannels: numChannels,
          androidConfig: AndroidRecordConfig(
            service: AndroidService(title: 'Title', content: 'Content...'),
          ),
        ),
      );
      stream.listen(
        onData,
        onError: onError,
        onDone: onDone,
        cancelOnError: cancelOnError,
      );
    } else {
      onError("Permission not granted.");
    }
  }

  @override
  Future<void> pause() async {
    if (!(await record.isRecording())) {
      debugPrint("Not recording.");
      return;
    }
    return record.pause();
  }

  @override
  Future<void> resume() async {
    if (!(await record.isPaused())) {
      debugPrint("Not pausing.");
      return;
    }
    return record.resume();
  }

  @override
  Future<String?> stop() async {
    if (!(await record.isRecording()) && !(await record.isPaused())) {
      debugPrint("Not recording.");
      return null;
    }
    return await record.stop();
  }

  @override
  Future<void> dispose() {
    return record.dispose();
  }
}
