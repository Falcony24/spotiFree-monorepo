import 'package:flutter/material.dart';
import 'package:spotifree/models/album.dart';

class AlbumGridItem extends StatelessWidget {
  final Album album;
  final VoidCallback? onTap;

  const AlbumGridItem({super.key, required this.album, this.onTap});

  static Color _colorForId(String id) {
    final hash = id.codeUnits.fold<int>(0, (prev, c) => prev + c);
    return HSLColor.fromAHSL(0.7, (hash % 360).toDouble(), 0.45, 0.35).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _colorForId(album.id);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  colors: [bgColor, bgColor.withAlpha(120)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Center(
                child: Icon(Icons.album, size: 48, color: Colors.white70),
              ),
            ),
          ),
          const SizedBox(height: 8), 
          Text(
            album.title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (album.artist != null)
            Text(
              album.artist!,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(140),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}