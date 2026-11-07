import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/report_photo.dart';

const _maxPhotoBytes = 5 * 1024 * 1024;
const _allowedExtensions = ['.jpg', '.jpeg', '.png'];

/// Optional photo attachment: pick from camera or gallery, preview, remove.
/// Camera/photo permission is only requested when the student taps a button.
class PhotoPickerField extends StatelessWidget {
  const PhotoPickerField({
    super.key,
    required this.photoPath,
    required this.onChanged,
  });

  final String? photoPath;
  final ValueChanged<String?> onChanged;

  Future<void> _pick(BuildContext context, ImageSource source) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      // Resizing also converts HEIC photos from iPhones to JPEG.
      final file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 80,
      );
      if (file == null) return;

      final path = file.path.toLowerCase();
      if (!_allowedExtensions.any(path.endsWith)) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Choose a JPG or PNG photo.')),
        );
        return;
      }
      if (await file.length() > _maxPhotoBytes) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Photos must be 5 MB or smaller.')),
        );
        return;
      }
      onChanged(file.path);
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Camera or photo access is off. You can allow it in Settings, '
            'or continue without a photo.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final path = photoPath;
    final buttons = Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _pick(context, ImageSource.camera),
            icon: const Icon(Icons.photo_camera_outlined, size: 18),
            label: const Text('Take photo'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _pick(context, ImageSource.gallery),
            icon: const Icon(Icons.photo_library_outlined, size: 18),
            label: const Text('Choose photo'),
          ),
        ),
      ],
    );

    if (path == null) {
      return Column(
        children: [
          // Sized by its content (not a fixed height) so large system
          // text doesn't spill out of the box.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.colors.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_photo_alternate_outlined,
                  color: context.colors.primary,
                ),
                SizedBox(height: 6),
                Text(
                  'A photo helps staff find the issue faster',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.colors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          buttons,
          const SizedBox(height: 6),
          Text(
            'JPG or PNG, up to 5 MB.',
            style: TextStyle(color: context.colors.muted, fontSize: 12),
          ),
        ],
      );
    }

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: ReportPhoto(path: path, height: 180, width: double.infinity),
        ),
        const SizedBox(height: 10),
        buttons,
        TextButton.icon(
          onPressed: () => onChanged(null),
          icon: const Icon(Icons.close),
          label: const Text('Remove photo'),
        ),
      ],
    );
  }
}
