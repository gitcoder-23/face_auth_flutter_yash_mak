import 'package:image/image.dart' as imglib;
import 'package:camera/camera.dart';
import 'dart:typed_data'; // For ByteBuffer

import '../../utils/utils.dart';

imglib.Image? convertToImage(CameraImage image) {
  try {
    if (image.format.group == ImageFormatGroup.yuv420) {
      return _convertYUV420(image);
    } else if (image.format.group == ImageFormatGroup.bgra8888) {
      return _convertBGRA8888(image);
    }
    throw Exception('Image format not supported');
  } catch (e) {
    printIfDebug("ERROR:" + e.toString());
  }
  return null;
}

// imglib.Image _convertBGRA8888(CameraImage image) {
//   return imglib.Image.fromBytes(
//     image.width,
//     image.height,
//     image.planes[0].bytes,
//     format: imglib.Format.bgra,
//   );
// }

// imglib.Image _convertBGRA8888(CameraImage image) {
//   final bytes = image.planes[0].bytes.buffer.asByteData();

//   return imglib.Image.fromBytes(
//     width: image.width,
//     height: image.height,
//     bytes: bytes.buffer, // Pass the raw byte buffer here
//     format: imglib.Format.bgra, // Specify BGRA format
//   );
// }

imglib.Image _convertBGRA8888(CameraImage image) {
  final bytes = image.planes[0].bytes.buffer.asByteData();

  // Convert BGRA to RGBA
  List<int> convertedBytes = [];
  for (int i = 0; i < bytes.lengthInBytes; i += 4) {
    int b = bytes.getUint8(i); // Blue
    int g = bytes.getUint8(i + 1); // Green
    int r = bytes.getUint8(i + 2); // Red
    int a = bytes.getUint8(i + 3); // Alpha

    // Reorder bytes to RGBA
    convertedBytes.add(r); // Red
    convertedBytes.add(g); // Green
    convertedBytes.add(b); // Blue
    convertedBytes.add(a); // Alpha
  }

  // Create a new byte buffer with the converted data
  final convertedByteBuffer = Uint8List.fromList(convertedBytes).buffer;

  return imglib.Image.fromBytes(
    width: image.width,
    height: image.height,
    bytes: convertedByteBuffer,
    format: imglib.Format
        .uint8, // Use uint8 format, since no specific format like RGBA exists
  );
}

imglib.Image _convertYUV420(CameraImage image) {
  int width = image.width;
  int height = image.height;

  // Create a new image with the correct dimensions
  var img = imglib.Image(width: width, height: height);

  final int uvyButtonStride = image.planes[1].bytesPerRow;
  final int? uvPixelStride = image.planes[1].bytesPerPixel;

  // Process each pixel in the image and convert YUV to RGB
  for (int x = 0; x < width; x++) {
    for (int y = 0; y < height; y++) {
      final int uvIndex =
          uvPixelStride! * (x / 2).floor() + uvyButtonStride * (y / 2).floor();
      final int index = y * width + x;
      final yp = image.planes[0].bytes[index];
      final up = image.planes[1].bytes[uvIndex];
      final vp = image.planes[2].bytes[uvIndex];

      // Convert YUV to RGB using the standard formula
      int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
      int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91)
          .round()
          .clamp(0, 255);
      int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);

      // Create a Color object using fromARGB with Alpha, Red, Green, and Blue
      var color = imglib.ColorFloat16.rgba(255, r, g, b);

      // Set the pixel data in the final image using setPixel
      img.setPixel(x, y, color); // Use the Color object
    }
  }

  return img;
}

// imglib.Image _convertYUV420(CameraImage image) {
//   int width = image.width;
//   int height = image.height;
//   var img = imglib.Image(width, height);
//   const int hexFF = 0xFF000000;
//   final int uvyButtonStride = image.planes[1].bytesPerRow;
//   final int? uvPixelStride = image.planes[1].bytesPerPixel;
//   for (int x = 0; x < width; x++) {
//     for (int y = 0; y < height; y++) {
//       final int uvIndex =
//           uvPixelStride! * (x / 2).floor() + uvyButtonStride * (y / 2).floor();
//       final int index = y * width + x;
//       final yp = image.planes[0].bytes[index];
//       final up = image.planes[1].bytes[uvIndex];
//       final vp = image.planes[2].bytes[uvIndex];
//       int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
//       int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91)
//           .round()
//           .clamp(0, 255);
//       int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);
//       img.data[index] = hexFF | (b << 16) | (g << 8) | r;
//     }
//   }

//   return img;
// }
