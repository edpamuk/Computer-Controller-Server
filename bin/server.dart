import 'dart:io';
import 'package:args/args.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'compController.dart';

// For Google Cloud Run, set _hostname to '0.0.0.0'.
const _hostname = 'YOUR_LAN_IP';
int? port = 8080;
void main(List<String> args) async {
  var parser = ArgParser()..addOption('port', abbr: 'p');
  var result = parser.parse(args);

  // For Google Cloud Run, we respect the PORT environment variable
  var portStr = result['port'] ?? Platform.environment['PORT'] ?? '8080';
  port = int.tryParse(portStr);

  if (port == null) {
    stdout.writeln('Could not parse port value "$portStr" into a number.');
    // 64: command line usage error
    exitCode = 64;
    return;
  }
  final handler = const shelf.Pipeline()
      .addMiddleware(shelf.logRequests())
      .addHandler(CompController().handler);
  var server = await io.serve(handler, _hostname, port!);
  print('Serving at http://${server.address.host}:${server.port}');
}
