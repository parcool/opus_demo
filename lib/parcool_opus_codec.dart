import 'dart:typed_data';

import 'package:opus_dart/opus_dart.dart';
import 'package:opus_demo/parcool_data_converter.dart';

class ParcoolOpusConverter {
  final int sampleRate;
  final int channels;

  ParcoolOpusConverter({required this.sampleRate, required this.channels});

  SimpleOpusEncoder? encoder;
  SimpleOpusDecoder? decoder;

  Uint8List pcmToOpus(Uint8List pcmData) {
    // create or recreate encoder if encoder not the same instance
    if (encoder == null ||
        encoder?.sampleRate != sampleRate ||
        encoder?.channels != channels) {
      encoder = SimpleOpusEncoder(
        sampleRate: sampleRate,
        channels: channels,
        application: Application.audio,
      );
    }
    final pcmDataInt16List = uint8ListToInt16List(pcmData);
    return encoder!.encode(input: pcmDataInt16List);
  }

  Uint8List pcmToOpusInt16List(Int16List pcmDataInt16List) {
    // create or recreate encoder if encoder not the same instance
    if (encoder == null ||
        encoder?.sampleRate != sampleRate ||
        encoder?.channels != channels) {
      encoder = SimpleOpusEncoder(
        sampleRate: sampleRate,
        channels: channels,
        application: Application.audio,
      );
    }
    return encoder!.encode(input: pcmDataInt16List);
  }

  Int16List opusToPcm(Uint8List opusData) {
    if (decoder == null ||
        decoder?.sampleRate != sampleRate ||
        decoder?.channels != channels) {
      decoder = SimpleOpusDecoder(sampleRate: sampleRate, channels: channels);
    }

    return decoder!.decode(input: opusData);
  }

  void dispose() {
    encoder?.destroy();
    decoder?.destroy();
  }
}
