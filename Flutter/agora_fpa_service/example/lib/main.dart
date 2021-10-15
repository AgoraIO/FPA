import 'package:agora_fpa_service/agora_fpa_service.dart';
import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> implements FpaServiceObserver {
  static const String upload_http_url = "http://148.153.93.30:30103/upload";
  static const String download_http_url = "http://148.153.93.30:30103/10MB.txt";
  static const String download_http_url2 = "http://148.153.93.30:30103/5MB.txt";
  static const String upload_https_url =
      "https://frank-web-demo.rtns.sd-rtn.com:30113/upload";
  static const String download_https_url =
      "https://frank-web-demo.rtns.sd-rtn.com:30113/1MB.txt";

  String info = 'Log';

  late final Dio _dio;
  late final FpaService agoraFpaService;

  bool _uploadHttpsEnabled = false;
  bool _uploadHttpEnabled = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() async {
    FpaConfig fpaConfig = FpaConfig(
      appId: 'aab8b8f5a8cd4469a63042fcfafe7063',
      token: 'aab8b8f5a8cd4469a63042fcfafe7063',
      chainIdTable: {
        "www.qq.com": 259,
        "frank-web-demo.rtns.sd-rtn.com:30113": 254,
        "148.153.93.30:30103": 204,
      },
    );
    agoraFpaService = FpaService.create();
    agoraFpaService.registerObserver(this);
    agoraFpaService.start(fpaConfig);

    _dio = Dio();
    (_dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
        (client) {
      // config the http client
      client.findProxy = (uri) {
        final port = agoraFpaService.getHttpProxyPort();
        return 'PROXY $kBaseHost:$port';
      };
    };
  }

  @override
  void dispose() {
    agoraFpaService.unregisterObserver();
    agoraFpaService.destroy();
    super.dispose();
  }

  void _download(String url, String fileName) async {
    final status = await Permission.storage.request();

    if (!status.isGranted) return;
    final externalStorage = await getApplicationDocumentsDirectory();

    Stopwatch stopwatch = Stopwatch();
    stopwatch.start();
    final originInfo = info;
    await _dio.download(
      url,
      path.join(externalStorage.absolute.path, fileName),
      onReceiveProgress: (int count, int total) {
        setState(() {
          info = originInfo + '\nDownloading $fileName: $count/$total';
        });
      },
    );
    stopwatch.stop();
    setState(() {
      info +=
          '\nDownload complated, time: ${stopwatch.elapsedMilliseconds}ms\n';
      if (url.startsWith('https')) {
        _uploadHttpsEnabled = true;
      } else {
        _uploadHttpEnabled = true;
      }
    });
  }

  Future<void> _upload(String url, String fileName) async {
    final externalStorage = await getApplicationDocumentsDirectory();

    FormData formData = FormData.fromMap({
      "file": await MultipartFile.fromFile(
          path.join(externalStorage.absolute.path, fileName),
          filename: fileName),
    });

    Stopwatch stopwatch = Stopwatch();
    stopwatch.start();
    final originInfo = info;
    await _dio.post(url, data: formData,
        onSendProgress: (int count, int total) {
      setState(() {
        info = originInfo + '\nUploading $fileName: $count/$total';
      });
    });
    stopwatch.stop();
    setState(() {
      info += '\nUpload complated, time: ${stopwatch.elapsedMilliseconds}ms\n';
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Fpa Service example app'),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(download_https_url),
            TextButton(
              onPressed: () {
                _download(download_https_url, 'download1M.pptx');
              },
              child: const Text('Download Https'),
            ),
            const Text(upload_https_url),
            TextButton(
              onPressed: _uploadHttpsEnabled
                  ? () {
                      _upload(upload_https_url, 'download1M.pptx');
                    }
                  : null,
              child: const Text('Upload Https'),
            ),
            const Text(download_http_url),
            TextButton(
              onPressed: () {
                _download(download_http_url, 'download10M.pptx');
              },
              child: const Text('Download Http'),
            ),
            const Text(upload_http_url),
            TextButton(
                onPressed: _uploadHttpEnabled
                    ? () {
                        _upload(upload_http_url, 'download10M.pptx');
                      }
                    : null,
                child: const Text('Upload Http')),
            Expanded(
              child: SingleChildScrollView(
                child: Text(info),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void onTokenWillExpireEvent(String token) {}

  @override
  void onEvent(int event, int errorCode) {
    info += '\nService event: $event, error code: $errorCode';
  }
}
