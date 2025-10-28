import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:opus_demo/parcool_data_converter.dart';

const int wavHeaderSize = 44;

class ParcoolFileUtil {
  final int sampleRate;
  final int channels;
  List<Uint8List> output = [];

  ParcoolFileUtil({required this.sampleRate, required this.channels}) {
    _reset();
  }

  void add(Int16List pcmData) {
    output.add(int16ListToUint8List(pcmData));
  }

  void save({required String path}) {
    int length = output.fold(
      0,
      (int l, Uint8List element) => l + element.length,
    );
    Uint8List header = wavHeader(
      channels: channels,
      sampleRate: sampleRate,
      fileSize: length,
    );
    output[0] = header;
    Uint8List flat = Uint8List(length);
    int index = 0;
    for (Uint8List element in output) {
      flat.setAll(index, element);
      index += element.length;
    }
    final file = File(path);
    if (!file.existsSync()) {
      file.createSync(recursive: true);
    }
    file.writeAsBytesSync(flat);
    // 最后reset一下随时做好下次重来的准备
    _reset();
  }

  void _reset() {
    output.clear();
    output.add(Uint8List(wavHeaderSize)); //Reserve space for the header
  }
}

Uint8List wavHeader({
  required int sampleRate,
  required int channels,
  required int fileSize,
}) {
  const int sampleBits = 16; //We know this since we used opus
  const Endian endian = Endian.little;
  final int frameSize = ((sampleBits + 7) ~/ 8) * channels;
  ByteData data = ByteData(wavHeaderSize);
  data.setUint32(4, fileSize - 4, endian);
  data.setUint32(16, 16, endian);
  data.setUint16(20, 1, endian);
  data.setUint16(22, channels, endian);
  data.setUint32(24, sampleRate, endian);
  data.setUint32(28, sampleRate * frameSize, endian);
  data.setUint16(30, frameSize, endian);
  data.setUint16(34, sampleBits, endian);
  data.setUint32(40, fileSize - 44, endian);
  Uint8List bytes = data.buffer.asUint8List();
  bytes.setAll(0, ascii.encode('RIFF'));
  bytes.setAll(8, ascii.encode('WAVE'));
  bytes.setAll(12, ascii.encode('fmt '));
  bytes.setAll(36, ascii.encode('data'));
  return bytes;
}
