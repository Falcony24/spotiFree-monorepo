import 'package:flutter/material.dart';
import 'package:spotifree/models/album.dart';

class AlbumGridItem extends StatelessWidget {
  final Album album;
  final VoidCallback? onTap;

  const AlbumGridItem({super.key, required this.album, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8), 
              ),
              child: const Center(
                child: Icon(Icons.album, size: 48, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 8), 
          Text(
            album.title,
            style: const TextStyle(fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          if (album.artist != null)
            Text(
              album.artist!,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}