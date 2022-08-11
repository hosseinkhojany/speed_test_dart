# speed_test_dart

Forked from [speed_test_port](https://pub.dev/packages/speed_test_port)

Flutter package to test ping, upload, download using speedtest.net

## Optimizations

Some refactors, more customization.

## Installation

Add the package to your dependencies:

```yaml
dependencies:
  speed_test_dart: ^1.0.0
```

Finally, run `dart pub get` to download the package.

Projects using this library should use the stable channel of Flutter

## Example of usage

```dart
    SpeedTest tester = SpeedTest();

    //Getting closest servers
    var settings = await tester.GetSettings();

    var servers = settings.servers;

    //Test latency for each server
    for (var server in servers) {
      server.Latency = await tester.testServerLatency(server, 3);
    }

    //Getting best server
    servers.sort((a, b) => a.latency.compareTo(b.Latency));
    var bestServer = servers.first;

    //Test download speed in MB/s
    var downloadSpeed = await tester.testDownloadSpeed(
        bestServer,
        settings.download.threadsPerUrl == 0
            ? 2
            : settings.download.threadsPerUrl,
        3);

    //Test upload speed in MB/s
    var uploadSpeed = await tester.testUploadSpeed(
        bestServer,
        settings.upload.threadsPerUrl == 0 ? 2 : settings.upload.threadsPerUrl,
        3);

```
