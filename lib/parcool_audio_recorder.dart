import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:record/record.dart';

import 'parcool_data_converter.dart';
import 'parcool_opus_codec.dart';

/// 录制中会直接返回经过编码后的opusData
typedef AudioDataCallback = void Function(Uint8List opusData);

/// 录制完成后的回调
typedef DoneCallback = void Function();

/// 错误回调
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

  final ParcoolOpusConverter converter;

  File? fileForStream;

  ParcoolAudioRecorder({
    required this.sampleRate,
    required this.numChannels,
    required this.onData,
    required this.onDone,
    required this.onError,
    required this.converter,
    this.cancelOnError = true,
  }) {
    record = AudioRecorder();
  }

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
        ),
      );
      stream.listen(
        (data) => _processPcmChunk(data, onData, onError),
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

  final List<int> _pcmBuffer = [];
  late final int _opusFrameSize = (sampleRate * numChannels * 0.02)
      .toInt(); // opus的encoder需要配置为2.5ms, 5ms, 10ms, 20ms, 40ms and 60ms，这里选取配置的0.02是20ms

  void _processPcmChunk(
    Uint8List pcmDataChunk,
    AudioDataCallback onData,
    ErrorCallback onError,
  ) {
    Int16List pcmSamples;
    try {
      pcmSamples = uint8ListToInt16List(pcmDataChunk);
    } catch (e) {
      debugPrint("Error converting PCM data: $e");
      onError(e);
      return;
    }
    _pcmBuffer.addAll(pcmSamples);
    while (_pcmBuffer.length >= _opusFrameSize) {
      final Int16List opusFrame = Int16List.fromList(
        _pcmBuffer.sublist(0, _opusFrameSize),
      );
      _pcmBuffer.removeRange(0, _opusFrameSize);
      try {
        final opusData = converter.pcmToOpusInt16List(opusFrame);
        onData(opusData);
      } catch (e) {
        debugPrint("Opus encode error: $e");
        onError(e);
      }
    }
  }
}
