import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:shelf_router/shelf_router.dart';
import 'package:shelf/shelf.dart' as shelf;

class CompController {
  shelf.Handler get handler {
    final router = Router();

    router.get('/files/', (shelf.Request request) {
      return shelf.Response.ok("body");
    });

    router.post('/delete/', (shelf.Request request) async {
      var data = Utf8Decoder().bind(request.read());
      var payload = await data.toList();
      for (var i in payload) {
        await CompController.delete(i);
      }
      return shelf.Response.ok('File Deleted');
    });
    router.post('/add/', () {});
    router.post('/read/', (shelf.Request request) async {
      var data = Utf8Decoder().bind(request.read());
      var payload = await data.toList();
      if (payload.isEmpty) {
        return shelf.Response.forbidden('file not provided');
      }
      final fileAsBytes = await CompController.getBytes(payload.first);
      return shelf.Response.ok(fileAsBytes);
    });
    router.post('/update/', (shelf.Request request) async {
      final rawData = await Utf8Decoder().bind(request.read()).first;
      final Map<String, dynamic> data = jsonDecode(rawData);
      try {
        final path = data['file']!;
        final content = data['content']!;
        await CompController.update(path, content);
      } catch (e) {
        print(data);
        print(e);
      }
      return shelf.Response.ok('');
    });
    router.mount('/get/', (request) async {
      var data = Utf8Decoder().bind(request.read());
      var payload = await data.toList();
      if (payload.isEmpty) {
        return shelf.Response.forbidden("No Directory Provided");
      }
      final entities = CompController.getFileNames(payload.first);
      final future = await entities.toList();
      final names = future.map((e) => e.path);
      final resp = Utf8Encoder().bind(Stream.fromIterable(names));
      return shelf.Response.ok(resp);
    });
    router.all('/<ignored|.*/',
        (shelf.Request request) => shelf.Response.notFound("not found"));
    return router;
  }

  static Future<void> delete(String filePath) async {
    await File(filePath).delete();
  }

  static Future<File> create(String filePath, List<int> payload) {
    return File(filePath).writeAsBytes(payload);
  }

  static Future<Uint8List> getBytes(String filepath) async {
    var file = File(filepath);
    return await file.exists()
        ? File(filepath).readAsBytes()
        : Future.value(Uint8List(0));
  }

  static Future<void> update(String filePath, String payload) {
    return File(filePath)
        .exists()
        .then((value) => value ? File(filePath).writeAsString(payload) : null);
  }

  static Stream<FileSystemEntity> getFileNames(String directoryPath) {
    return Directory(directoryPath).list();
  }
}
