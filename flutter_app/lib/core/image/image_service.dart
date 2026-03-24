import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

class ImageService {
  static const _maxDimension = 1920;
  static const _jpegQuality = 85;

  Future<String> saveImage(File sourceFile) async {
    final dir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(dir.path, 'images'));
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    final id = const Uuid().v4();
    final destPath = p.join(imagesDir.path, '$id.jpg');

    final bytes = await sourceFile.readAsBytes();
    var image = img.decodeImage(bytes);
    if (image == null) {
      await sourceFile.copy(destPath);
      return destPath;
    }

    if (image.width > _maxDimension || image.height > _maxDimension) {
      image = img.copyResize(
        image,
        width: image.width > image.height ? _maxDimension : null,
        height: image.height >= image.width ? _maxDimension : null,
      );
    }

    final jpeg = img.encodeJpg(image, quality: _jpegQuality);
    await File(destPath).writeAsBytes(jpeg);

    return destPath;
  }

  Future<void> deleteImage(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}

final imageServiceProvider = Provider<ImageService>((ref) => ImageService());
