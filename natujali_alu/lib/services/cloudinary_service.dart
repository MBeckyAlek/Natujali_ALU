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
    final result = jsonDecode(responseBody) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      return result['secure_url'] as String;
    }

    final errorMessage = result['error']?['message'] ?? 'Image upload failed';
    throw Exception(errorMessage);
  }
}
