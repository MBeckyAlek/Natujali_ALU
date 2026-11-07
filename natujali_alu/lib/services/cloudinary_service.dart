import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Uploads report photos to Cloudinary and returns their public URL, which
/// is what gets saved on the report in Firestore.
///
/// Uses an unsigned upload preset, so no secret key is kept in the app.
/// Limit the preset in the Cloudinary console (formats, size, folder).
class CloudinaryService {
  static const String cloudName = 'swznkdto';
  static const String uploadPreset = 'natujali_alu';

  Future<String> uploadImage(File image) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..fields['folder'] = 'reports'
      ..files.add(await http.MultipartFile.fromPath('file', image.path));

    final response = await request.send().timeout(const Duration(seconds: 60));
    final responseBody = await response.stream.bytesToString();
    final Map<String, dynamic> result;
    try {
      result = jsonDecode(responseBody) as Map<String, dynamic>;
    } on FormatException {
      throw PhotoUploadException('server replied ${response.statusCode}');
    }

    if (response.statusCode == 200) {
      return result['secure_url'] as String;
    }

    final errorMessage = result['error']?['message'] ?? 'Image upload failed';
    throw PhotoUploadException(errorMessage as String);
  }
}

/// Cloudinary rejected the photo, e.g. a missing upload preset or a file
/// that is too large. The message comes from Cloudinary.
class PhotoUploadException implements Exception {
  const PhotoUploadException(this.message);

  final String message;

  @override
  String toString() => 'PhotoUploadException: $message';
}
