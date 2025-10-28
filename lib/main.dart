import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:opus_dart/opus_dart.dart';
import 'package:opus_demo/parcool_audio_recorder.dart';
import 'package:opus_flutter/opus_flutter.dart' as opus_flutter;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'parcool_file_util.dart';
import 'parcool_opus_codec.dart';

void main() async {
  // 1. 初始化opus
  WidgetsFlutterBinding.ensureInitialized();
  initOpus(await opus_flutter.load());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final IAudioRecorder recorder;
  late final ParcoolOpusConverter converter;
  late final ParcoolFileUtil fileUtil; // 用来测试保存到本地的工具类 [仅仅测试需要该代码]
  final int sampleRate = 16000;
  final int numChannels = 1;

  bool _isRecording = false;
  String? _savedPath;

  @override
  void initState() {
    // 2. 初始化recorder与convert
    _initConverter();// 需要先调用_initConverter()再调用_initRecorder()
    _initRecorder();
    _initFileUtil();
    super.initState();
  }

  /// 初始化recorder
  void _initRecorder() {
    recorder = ParcoolAudioRecorder(
      sampleRate: sampleRate,
      numChannels: numChannels,
      converter: converter,
      onData: (Uint8List opusData) {
        // TODO: 这里可以直接使用这个opusData了，比如：sendOpusDataToServer(opusData)
        // 保存到本地文件 [仅仅测试需要下面的代码]
        final pcmData = converter.opusToPcm(opusData);
        fileUtil.add(pcmData);
      },
      onDone: () async {
        // 这是完成录制后的回调，此处用来保存文件到本地测试是否正常用的，如果用不到可以删掉这些代码
        final Directory appDir = await getApplicationDocumentsDirectory();
        final String filePath =
            '${appDir.path}/my_new_recording${DateTime.now().millisecondsSinceEpoch}.wav';
        fileUtil.save(path: filePath);
        setState(() {
          _savedPath = filePath;
        });
        debugPrint("文件已保存到：$filePath");
      },
      onError: (error) {},
    );
  }

  /// 初始化converter
  void _initConverter() {
    converter = ParcoolOpusConverter(
      sampleRate: sampleRate,
      channels: numChannels,
    );
  }

  /// 初始化fileUtil。[仅仅测试需要该方法]
  void _initFileUtil() {
    fileUtil = ParcoolFileUtil(sampleRate: sampleRate, channels: numChannels);
  }

  /// 分享 [仅仅测试需要该方法]
  void _share() async {
    final params = ShareParams(text: 'WAV文件', files: [XFile(_savedPath!)]);

    final result = await SharePlus.instance.share(params);

    if (result.status == ShareResultStatus.success) {
      debugPrint('Share success!');
    }
  }

  /// 开始录音
  void _startRecording() {
    recorder.start();
    setState(() {
      _savedPath = null;
      _isRecording = true;
    });
  }

  /// 停止录音
  void _stopRecording() {
    recorder.stop();
    setState(() {
      _isRecording = false;
    });
  }

  @override
  void dispose() {
    // 为了内存健康最好也回收掉相关
    converter.dispose();
    recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: _isRecording
                  ? null
                  : () {
                      // 3. start
                      _startRecording();
                    },
              child: Text("开始录制"),
            ),
            ElevatedButton(
              onPressed: _isRecording
                  ? () {
                      // 4. stop
                      _stopRecording();
                    }
                  : null,
              child: Text("停止录制"),
            ),
            if (_savedPath != null) Text("文件已经保存到：$_savedPath"),
            if (_savedPath != null)
              ElevatedButton(
                onPressed: _savedPath != null ? _share : null,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [const Icon(Icons.ios_share), Text("分享")],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
