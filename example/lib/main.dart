import 'package:flutter/material.dart';
import 'package:speed_test_dart/classes/classes.dart';
import 'package:speed_test_dart/speed_test_dart.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  SpeedTestDart tester = SpeedTestDart();
  Server? server;

  double downloadRate = 0;
  double uploadRate = 0;

  bool readyToTest = false;
  bool loadingDownload = false;
  bool loadingUpload = false;

  Future<void> setServer() async {
    final settings = await tester.getSettings();

    final servers = settings.servers;

    //Test latency for each server
    for (var s in servers) {
      try {
        final latency = await tester.testServerLatency(s, 1);
        print(latency);
      } catch (e) {
        print(e);
      }
    }
    print('ok');
    //Getting best server
    servers.sort((a, b) => a.latency.compareTo(b.latency));

    setState(() {
      server = servers.first;
      readyToTest = true;
    });
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setServer();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Speed Test Example App'),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Download Test:',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              if (loadingDownload)
                const CircularProgressIndicator()
              else
                Text('Download rate  ${downloadRate.toStringAsFixed(2)} Mb/s'),
              const SizedBox(
                height: 10,
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  primary: readyToTest ? Colors.blue : Colors.grey,
                ),
                child: const Text('Start'),
                onPressed: () async {
                  if (!readyToTest || server == null) return;

                  setState(() {
                    loadingDownload = true;
                  });
                  final _downloadRate =
                      await tester.testDownloadSpeed(server!, 2, 3);
                  setState(() {
                    downloadRate = _downloadRate;
                    loadingDownload = false;
                  });
                },
              ),
              const SizedBox(
                height: 50,
              ),
              const Text(
                'Upload Test:',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              if (loadingUpload)
                const CircularProgressIndicator()
              else
                Text('Upload rate ${uploadRate.toStringAsFixed(2)} Mb/s'),
              const SizedBox(
                height: 10,
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  primary: readyToTest ? Colors.blue : Colors.grey,
                ),
                child: const Text('Start'),
                onPressed: () async {
                  if (!readyToTest || server == null) return;

                  setState(() {
                    loadingUpload = true;
                  });

                  final _uploadRate =
                      await tester.testUploadSpeed(server!, 2, 3);

                  setState(() {
                    uploadRate = _uploadRate;
                    loadingUpload = false;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
