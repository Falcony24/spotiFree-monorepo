import 'package:flutter/material.dart';
import 'package:spotifree/models/track.dart';

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
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return IconButton(
      icon: Icon(
        widget.isDownloaded ? Icons.check_circle : Icons.download,
        size: 20,
        color: widget.isDownloaded
            ? Theme.of(context).colorScheme.primary
            : Colors.white54,
      ),
      visualDensity: VisualDensity.compact,
      onPressed: () async {
        if (widget.isDownloaded) {
          widget.onDelete();
        } else {
          setState(() => _isDownloading = true);
          try {
            widget.onDownload();
          } finally {
            if (mounted) setState(() => _isDownloading = false);
          }
        }
      },
    );
  }
}