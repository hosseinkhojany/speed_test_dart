library speed_test_dart;

import 'dart:async';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:speed_test_dart/classes/classes.dart';

import 'package:speed_test_dart/constants.dart';
import 'package:sync/sync.dart';
import 'package:xml_parser/xml_parser.dart';

/// A Speed tester.
class SpeedTestDart {
  /// Returns [Settings] from speedtest.net.
  Future<Settings> getSettings() async {
    final response = await http.get(Uri.parse(configUrl));
    final settings = Settings.fromXMLElement(
      XmlDocument.from(response.body)?.getElement('settings'),
    );

    var serversConfig = ServersList(<Server>[]);
    for (final element in serversUrls) {
      if (serversConfig.servers.isNotEmpty) break;
      try {
        final resp = await http.get(Uri.parse(element));

        serversConfig = ServersList.fromXMLElement(
          XmlDocument.from(resp.body)?.getElement('settings'),
        );
      } catch (ex) {
        serversConfig = ServersList(<Server>[]);
      }
    }

    final ignoredIds = settings.serverConfig.ignoreIds.split(',');
    serversConfig.calculateDistances(settings.client.geoCoordinate);
    settings.servers = serversConfig.servers
        .where(
          (s) => !ignoredIds.contains(s.id.toString()),
        )
        .toList();
    settings.servers.sort((a, b) => a.distance.compareTo(b.distance));

    return settings;
  }

  /// Returns [double] ping value for [Server].
  Future<double> testServerLatency(Server server, int retryCount) async {
    final latencyUri = createTestUrl(server, 'latency.txt');

    final stopwatch = Stopwatch();
    for (var i = 0; i < retryCount; i++) {
      String testString;
      try {
        stopwatch.start();
        testString = (await http.get(latencyUri)).body;
      } catch (ex) {
        continue;
      } finally {
        stopwatch.stop();
      }

      if (!testString.startsWith('test=test')) {
        throw Exception(
          'Server returned incorrect test string for latency.txt',
        );
      }
    }

    return stopwatch.elapsedMilliseconds / retryCount;
  }

  /// Creates [Uri] from [Server] and [String] file
  Uri createTestUrl(Server server, String file) {
    return Uri.parse(
      Uri.parse(server.url).toString().replaceAll('upload.php', file),
    );
  }

  /// Returns urls for download test.
  List<String> generateDownloadUrls(Server server, int retryCount) {
    final downloadUriBase = createTestUrl(server, 'random{0}x{0}.jpg?r={1}');
    final result = <String>[];
    for (final ds in downloadSizes) {
      for (var i = 0; i < retryCount; i++) {
        result.add(
          downloadUriBase
              .toString()
              .replaceAll('%7B0%7D', ds.toString())
              .replaceAll('%7B1%7D', i.toString()),
        );
      }
    }
    // downloadSizes.forEach((downloadSize) {
    //   for (var i = 0; i < retryCount; i++) {
    //     result.add(
    //       downloadUriBase
    //           .toString()
    //           .replaceAll('%7B0%7D', downloadSize.toString())
    //           .replaceAll('%7B1%7D', i.toString()),
    //     );
    //   }
    // });

    return result;
  }

  /// Returns [double] downloaded speed in MB/s.
  Future<double> testDownloadSpeed(
    Server server,
    int simultaneousDownloads,
    int retryCount,
  ) async {
    final testData = generateDownloadUrls(server, retryCount);

    final semaphore = Semaphore(simultaneousDownloads);

    final tasks = <Future<int>>[];
    final stopwatch = Stopwatch()..start();

    for (final td in testData) {
      tasks.add(
        Future<int>(() async {
          await semaphore.acquire();
          try {
            final data = await http.get(Uri.parse(td));
            return data.bodyBytes.length;
          } finally {
            semaphore.release();
          }
        }),
      );
    }
    // testData.forEach((element) {
    //   tasks.add(
    //     Future<int>(() async {
    //       await semaphore.acquire();
    //       try {
    //         final data = await http.get(Uri.parse(element));
    //         return data.bodyBytes.length;
    //       } finally {
    //         semaphore.release();
    //       }
    //     }),
    //   );
    // });

    final results = await Future.wait(tasks);

    stopwatch.stop();
    final totalSize = results.reduce((a, b) => a + b);
    return (totalSize * 8 / 1024) /
        (stopwatch.elapsedMilliseconds / 1000) /
        1000;
  }

  /// Returns [double] upload speed in MB/s.
  Future<double> testUploadSpeed(
    Server server,
    int simultaneousDownloads,
    int retryCount,
  ) async {
    final testData = generateUploadData(retryCount);

    final semaphore = Semaphore(simultaneousDownloads);

    final tasks = <Future<int>>[];
    final stopwatch = Stopwatch()..start();

    for (final td in testData) {
      tasks.add(
        Future<int>(() async {
          await semaphore.acquire();
          try {
            // final data = await http.post(Uri.parse(server.url), body: td);
            return td.length;
          } finally {
            semaphore.release();
          }
        }),
      );
    }

    // testData.forEach((element) {
    //   tasks.add(
    //     Future<int>(() async {
    //       semaphore.acquire();
    //       try {
    //         final data = await http.post(Uri.parse(server.Url), body: element);
    //         return element.length;
    //       } finally {
    //         semaphore.release();
    //       }
    //     }),
    //   );
    // });

    final results = await Future.wait(tasks);

    stopwatch.stop();
    final totalSize = results.reduce((a, b) => a + b);
    return (totalSize * 8 / 1024) /
        (stopwatch.elapsedMilliseconds / 1000) /
        1000;
  }

  /// Generate list of [String] urls for upload.
  List<String> generateUploadData(int retryCount) {
    final random = Random();
    final result = <String>[];

    for (var sizeCounter = 1; sizeCounter < maxUploadSize + 1; sizeCounter++) {
      final size = sizeCounter * 200 * 1024;
      final builder = StringBuffer()
        ..write('content ${sizeCounter.toString()}=');

      for (var i = 0; i < size; ++i) {
        builder.write(hars[random.nextInt(hars.length)]);
      }

      for (var i = 0; i < retryCount; i++) {
        result.add(builder.toString());
      }
    }

    return result;
  }
}
