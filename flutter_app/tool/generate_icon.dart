import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  const size = 1024;
  final image = img.Image(width: size, height: size);

  // Colors
  final cream = img.ColorRgba8(255, 248, 240, 255); // #FFF8F0
  final terracotta = img.ColorRgba8(212, 132, 90, 255); // #D4845A
  final yellow = img.ColorRgba8(242, 201, 76, 255); // #F2C94C
  final pageColor = img.ColorRgba8(255, 253, 248, 255); // near-white pages
  final textLineColor = img.ColorRgba8(200, 170, 145, 255); // light brown lines
  final spineColor = img.ColorRgba8(180, 100, 60, 255); // darker terracotta spine

  // Fill background with cream
  img.fill(image, color: cream);

  // Draw a circular background disc
  final cx = size ~/ 2;
  final cy = size ~/ 2;
  final radius = 440;
  img.fillCircle(image, x: cx, y: cy, radius: radius, color: terracotta);

  // Draw inner circle slightly smaller — cream — to create a ring effect
  img.fillCircle(image, x: cx, y: cy, radius: radius - 30, color: cream);

  // Book dimensions — centered
  const bookW = 560;
  const bookH = 380;
  const bookTop = (size - bookH) ~/ 2;
  const bookLeft = (size - bookW) ~/ 2;
  const bookBottom = bookTop + bookH;
  const bookRight = bookLeft + bookW;
  const spineX = size ~/ 2;
  const spineW = 24;
  const pageGap = 8;

  // Left page background
  img.fillRect(
    image,
    x1: bookLeft,
    y1: bookTop,
    x2: spineX - spineW ~/ 2 - pageGap,
    y2: bookBottom,
    color: pageColor,
  );

  // Right page background
  img.fillRect(
    image,
    x1: spineX + spineW ~/ 2 + pageGap,
    y1: bookTop,
    x2: bookRight,
    y2: bookBottom,
    color: pageColor,
  );

  // Spine
  img.fillRect(
    image,
    x1: spineX - spineW ~/ 2,
    y1: bookTop,
    x2: spineX + spineW ~/ 2,
    y2: bookBottom,
    color: spineColor,
  );

  // Draw text lines on left page
  const lineThickness = 6;
  const lineMargin = 40; // horizontal margin inside page
  const lineStartY = bookTop + 55;
  const lineSpacing = 42;
  const numLines = 7;

  final leftPageRight = spineX - spineW ~/ 2 - pageGap;
  final rightPageLeft = spineX + spineW ~/ 2 + pageGap;

  for (var i = 0; i < numLines; i++) {
    final lineY = lineStartY + i * lineSpacing;
    // Left page lines
    img.fillRect(
      image,
      x1: bookLeft + lineMargin,
      y1: lineY,
      x2: leftPageRight - lineMargin,
      y2: lineY + lineThickness,
      color: textLineColor,
    );
    // Right page lines
    img.fillRect(
      image,
      x1: rightPageLeft + lineMargin,
      y1: lineY,
      x2: bookRight - lineMargin,
      y2: lineY + lineThickness,
      color: textLineColor,
    );
  }

  // Highlight one line on the right page (line index 2)
  const highlightLineIndex = 2;
  final highlightY = lineStartY + highlightLineIndex * lineSpacing - 6;
  final highlightH = lineThickness + 14;
  img.fillRect(
    image,
    x1: rightPageLeft + lineMargin - 4,
    y1: highlightY,
    x2: bookRight - lineMargin - 40, // slightly shorter for variety
    y2: highlightY + highlightH,
    color: yellow,
  );

  // Redraw the highlighted text line on top of the yellow bar
  img.fillRect(
    image,
    x1: rightPageLeft + lineMargin,
    y1: lineStartY + highlightLineIndex * lineSpacing,
    x2: bookRight - lineMargin - 44,
    y2: lineStartY + highlightLineIndex * lineSpacing + lineThickness,
    color: terracotta,
  );

  // Save
  Directory('assets/icon').createSync(recursive: true);
  File('assets/icon/app_icon.png').writeAsBytesSync(img.encodePng(image));
  print('Icon generated at assets/icon/app_icon.png');
}
