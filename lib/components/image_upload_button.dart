import '/backend/firebase_storage/storage.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/upload_data.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Pick an image, upload it, hand back the download URL.
///
/// The plumbing for this already existed - `selectMediaWithSourceBottomSheet`
/// and `uploadData` have been in the project since the start - and exactly
/// one page used it. Meanwhile `businesses.hero_image` was read in two
/// places and written by nothing at all, so no owner could ever set one and
/// every business fell back to the KIN logo permanently; and
/// `users.photo_url` only ever came from Firebase Auth, so anyone who
/// signed up with an email had no picture and no way to add one.
///
/// Written as one component rather than three copies of the 60-line upload
/// dance from mobile_called_power_page, which is what made it feel like too
/// much work to add the second and third time.
///
/// Uploads land under `users/{uid}/...`, which is the one path
/// storage.rules opens for writing - world-readable, writable only by the
/// owning user. A business hero therefore lives under the uploading owner's
/// path, which is correct: they are the only person entitled to change it.
class ImageUploadButton extends StatefulWidget {
  const ImageUploadButton({
    super.key,
    required this.onUploaded,
    this.label = 'Change photo',
    this.icon = Icons.photo_camera_rounded,
  });

  /// Called with the download URL once the upload succeeds. The caller
  /// decides which field it belongs in - this widget writes nothing to
  /// Firestore itself.
  final Future<void> Function(String downloadUrl) onUploaded;

  final String label;
  final IconData icon;

  @override
  State<ImageUploadButton> createState() => _ImageUploadButtonState();
}

class _ImageUploadButtonState extends State<ImageUploadButton> {
  bool _busy = false;

  Future<void> _pick() async {
    final media = await selectMediaWithSourceBottomSheet(
      context: context,
      // Bounded on the way in. An unresized phone photo is several
      // megabytes, and this image is shown in a 280px-tall header - paying
      // to store and re-download the full thing helps nobody.
      maxWidth: 1600.0,
      maxHeight: 1600.0,
      allowPhoto: true,
    );
    if (media == null || media.isEmpty) return;
    if (!media.every((m) => validateFileFormat(m.storagePath, context))) return;

    setState(() => _busy = true);
    String? url;
    try {
      url = await uploadData(media.first.storagePath, media.first.bytes);
    } catch (_) {
      url = null;
    } finally {
      if (mounted) setState(() => _busy = false);
    }

    if (!mounted) return;
    if (url == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload failed. Please try again.')),
      );
      return;
    }
    await widget.onUploaded(url);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Photo updated.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(999.0),
      onTap: _busy ? null : _pick,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
        decoration: BoxDecoration(
          // accent1 as the fill, primary as the label - the pairing that
          // holds in both themes. See the light-mode fixes on the business
          // profile for why a text token must never be used here.
          color: theme.accent1,
          borderRadius: BorderRadius.circular(999.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_busy)
              SizedBox(
                width: 16.0,
                height: 16.0,
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
                ),
              )
            else
              Icon(widget.icon, size: 18.0, color: theme.primary),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(8.0, 0, 0, 0),
              child: Text(
                _busy ? 'Uploading...' : widget.label,
                style: theme.labelMedium.override(
                  font: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600),
                  color: theme.primary,
                  letterSpacing: 0.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
