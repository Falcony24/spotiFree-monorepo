import 'package:flutter/material.dart';
import 'package:spotifree/l10n/app_localizations.dart';
import 'package:spotifree/providers/downloaded_tracks_provider.dart';
import 'package:spotifree/models/track.dart';
import 'package:provider/provider.dart';

class DownloadProgressDialog extends StatefulWidget {
  final List<Track> tracks;
  final VoidCallback onComplete;

  const DownloadProgressDialog({
    super.key,
    required this.tracks,
    required this.onComplete,
  });

  @override
  State<DownloadProgressDialog> createState() => _DownloadProgressDialogState();
}

class _DownloadProgressDialogState extends State<DownloadProgressDialog> {
  int completed = 0;
  int total = 0;
  bool isDownloading = true;
  bool _isDownloadStarted = false; 

  @override
  void initState() {
    super.initState();
    total = widget.tracks.length;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isDownloadStarted) {
      _isDownloadStarted = true;
      _startDownload();
    }
  }

  Future<void> _startDownload() async {
    final downloadedProvider = Provider.of<DownloadedTracksProvider>(context, listen: false);
    final t = AppLocalizations.of(context)!;
    
    try {
      await downloadedProvider.downloadTracks(
        widget.tracks,
        onProgress: (c, t) {
          if (mounted) {
            setState(() {
              completed = c;
              total = t;
            });
          }
        },
      );
      if (mounted) {
        setState(() => isDownloading = false);
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) Navigator.pop(context);
        widget.onComplete();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.downloadError(e.toString()))),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(t.downloading),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(value: total == 0 ? 0 : completed / total),
          const SizedBox(height: 8),
          Text(t.downloadedXOutOfY(completed, total)),
          if (!isDownloading)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Icon(Icons.check_circle, color: Colors.green),
            ),
        ],
      ),
    );
  }
}