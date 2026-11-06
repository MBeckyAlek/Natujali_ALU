import 'dart:io';

import 'package:flutter/material.dart';

/// Shows a report photo from either place it can live: a Cloudinary URL
/// once uploaded, or a file on this device while the form is being filled.
class ReportPhoto extends StatelessWidget {
  const ReportPhoto({
    super.key,
    required this.path,
    this.height,
    this.width,
    this.fallback = const SizedBox.shrink(),
  });

  final String path;
  final double? height;
  final double? width;

  /// Shown if the photo can't be loaded, e.g. when offline.
  final Widget fallback;

  bool get _isUploaded => path.startsWith('http');

  @override
  Widget build(BuildContext context) {
    if (_isUploaded) {
      return Image.network(
        path,
        height: height,
        width: width,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : SizedBox(
                height: height,
                width: width,
                child: const Center(child: CircularProgressIndicator()),
              ),
        errorBuilder: (_, _, _) => fallback,
      );
    }
    return Image.file(
      File(path),
      height: height,
      width: width,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => fallback,
    );
  }
}
