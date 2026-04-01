import 'package:flutter/material.dart';
import 'package:frontend/models/track.dart';

class DownloadButton extends StatefulWidget {
  final Track track;
  final bool isDownloaded;
  final VoidCallback onDownload;
  final VoidCallback onDelete;

  const DownloadButton({
    super.key,
    required this.track,
    required this.isDownloaded,
    required this.onDownload,
    required this.onDelete,
  });

  @override
  State<DownloadButton> createState() => _DownloadButtonState();
}

class _DownloadButtonState extends State<DownloadButton> {
  bool _isDownloading = false;

  @override
  Widget build(BuildContext context) {
    if (_isDownloading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return IconButton(
      icon: Icon(
        widget.isDownloaded ? Icons.check_circle : Icons.download,
        color: widget.isDownloaded ? Colors.green : Colors.white,
      ),
      onPressed: widget.isDownloaded ? widget.onDelete : widget.onDownload,
    );
  }
}