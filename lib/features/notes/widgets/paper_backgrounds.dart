import 'package:flutter/material.dart';

enum PaperType { ruled, grid, plain, dotGrid }

class PaperBackgroundWidget extends StatelessWidget {
  final PaperType paperType;
  final Color? lineColor;
  final Color? majorLineColor;
  final Color? minorLineColor;
  final double lineSpacing;
  final double majorGridSpacing;
  final double minorGridSpacing;
  final int majorLineInterval;
  final double margin;
  final Orientation orientation;
  final String? watermark;

  const PaperBackgroundWidget({
    super.key,
    this.paperType = PaperType.plain,
    this.lineColor,
    this.majorLineColor,
    this.minorLineColor,
    this.lineSpacing = 20.0,
    this.majorGridSpacing = 100.0,
    this.minorGridSpacing = 20.0,
    this.majorLineInterval = 5,
    this.margin = 20.0,
    this.orientation = Orientation.portrait,
    this.watermark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final effectiveLineColor = lineColor ?? (isDarkMode ? Colors.white54 : Colors.black54);
    final effectiveMajorLineColor = majorLineColor ?? (isDarkMode ? Colors.white38 : Colors.black38);
    final effectiveMinorLineColor = minorLineColor ?? (isDarkMode ? Colors.white24 : Colors.black26);

    return LayoutBuilder(
      builder: (context, constraints) {
        final a4AspectRatio = 210 / 297;
        double width, height;

        if (orientation == Orientation.portrait) {
          width = constraints.maxWidth;
          height = width / a4AspectRatio;
        } else {
          height = constraints.maxHeight;
          width = height / a4AspectRatio;
        }

        if (height > constraints.maxHeight) {
          height = constraints.maxHeight;
          width = height * a4AspectRatio;
        }
        if (width > constraints.maxWidth) {
          width = constraints.maxWidth;
          height = width / a4AspectRatio;
        }

        return RepaintBoundary(
          child: CustomPaint(
            size: Size(width, height),
            painter: _getPainter(paperType, effectiveLineColor, effectiveMajorLineColor, effectiveMinorLineColor),
          ),
        );
      },
    );
  }

  CustomPainter _getPainter(PaperType type, Color line, Color major, Color minor) {
    switch (type) {
      case PaperType.ruled:
        return RuledPaperPainter(
          lineColor: line,
          lineSpacing: lineSpacing,
          margin: margin,
        );
      case PaperType.grid:
        return GridPaperPainter(
          majorLineColor: major,
          minorLineColor: minor,
          majorGridSpacing: majorGridSpacing,
          minorGridSpacing: minorGridSpacing,
          margin: margin,
          majorLineInterval: majorLineInterval,
        );
      case PaperType.dotGrid:
        return DotGridPaperPainter(
          dotColor: line,
          dotSpacing: lineSpacing,
          margin: margin,
        );
      case PaperType.plain:
        return PlainPaperPainter(watermark: watermark);
    }
  }
}

class RuledPaperPainter extends CustomPainter {
  final Color lineColor;
  final double lineSpacing;
  final double margin;

  RuledPaperPainter({
    this.lineColor = Colors.grey,
    this.lineSpacing = 20.0,
    this.margin = 20.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 0.5;

    for (double y = margin; y < size.height - margin; y += lineSpacing) {
      canvas.drawLine(Offset(margin, y), Offset(size.width - margin, y), paint);
    }
  }

  @override
  bool shouldRepaint(RuledPaperPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor ||
        oldDelegate.lineSpacing != lineSpacing ||
        oldDelegate.margin != margin;
  }
}

class GridPaperPainter extends CustomPainter {
  final Color majorLineColor;
  final Color minorLineColor;
  final double majorGridSpacing;
  final double minorGridSpacing;
  final double margin;
  final int majorLineInterval;

  GridPaperPainter({
    this.majorLineColor = Colors.grey,
    this.minorLineColor = Colors.grey,
    this.majorGridSpacing = 100.0,
    this.minorGridSpacing = 20.0,
    this.margin = 20.0,
    this.majorLineInterval = 5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final majorPaint = Paint()
      ..color = majorLineColor
      ..strokeWidth = 0.75;
    final minorPaint = Paint()
      ..color = minorLineColor
      ..strokeWidth = 0.5;

    for (double x = margin; x < size.width - margin; x += minorGridSpacing) {
      final paint = ((x - margin) / minorGridSpacing) % majorLineInterval == 0
          ? majorPaint
          : minorPaint;
      canvas.drawLine(Offset(x, margin), Offset(x, size.height - margin), paint);
    }

    for (double y = margin; y < size.height - margin; y += minorGridSpacing) {
      final paint = ((y - margin) / minorGridSpacing) % majorLineInterval == 0
          ? majorPaint
          : minorPaint;
      canvas.drawLine(Offset(margin, y), Offset(size.width - margin, y), paint);
    }
  }

  @override
  bool shouldRepaint(GridPaperPainter oldDelegate) {
    return oldDelegate.majorLineColor != majorLineColor ||
        oldDelegate.minorLineColor != minorLineColor ||
        oldDelegate.majorGridSpacing != majorGridSpacing ||
        oldDelegate.minorGridSpacing != minorGridSpacing ||
        oldDelegate.margin != margin;
  }
}

class DotGridPaperPainter extends CustomPainter {
  final Color dotColor;
  final double dotSpacing;
  final double margin;

  DotGridPaperPainter({
    this.dotColor = Colors.grey,
    this.dotSpacing = 20.0,
    this.margin = 20.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = dotColor;

    for (double x = margin; x < size.width - margin; x += dotSpacing) {
      for (double y = margin; y < size.height - margin; y += dotSpacing) {
        canvas.drawCircle(Offset(x, y), 1.0, paint);
      }
    }
  }

  @override
  bool shouldRepaint(DotGridPaperPainter oldDelegate) {
    return oldDelegate.dotColor != dotColor ||
        oldDelegate.dotSpacing != dotSpacing ||
        oldDelegate.margin != margin;
  }
}

class PlainPaperPainter extends CustomPainter {
  final String? watermark;

  PlainPaperPainter({this.watermark});

  @override
  void paint(Canvas canvas, Size size) {
    if (watermark != null) {
      final textStyle = TextStyle(
        color: Colors.grey.withOpacity(0.1),
        fontSize: 48,
        fontWeight: FontWeight.bold,
      );
      final textSpan = TextSpan(
        text: watermark,
        style: textStyle,
      );
      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout(minWidth: 0, maxWidth: size.width);
      final offset = Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      );
      textPainter.paint(canvas, offset);
    }
  }

  @override
  bool shouldRepaint(PlainPaperPainter oldDelegate) {
    return oldDelegate.watermark != watermark;
  }
}