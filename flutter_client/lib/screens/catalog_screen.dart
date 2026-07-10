import 'package:flutter/material.dart';
import 'package:spotifree/l10n/app_localizations.dart';
import 'package:spotifree/widgets/album_grid_item.dart';
import 'package:provider/provider.dart';
import 'package:spotifree/providers/albums_provider.dart';
import 'package:spotifree/providers/mode_provider.dart';
import 'package:spotifree/screens/album_detail_screen.dart';
import 'package:spotifree/utils/responsive.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        final mode = Provider.of<ModeProvider>(context, listen: false);
        if (!mode.isOfflineMode) {
          Provider.of<AlbumsProvider>(context, listen: false).fetchAlbums(refresh: true);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AlbumsProvider>(context);
    final mode = Provider.of<ModeProvider>(context);
    final t = AppLocalizations.of(context)!;
    
    if (mode.isOfflineMode && provider.albums.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              t.offlineNoAlbums,
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              t.offlineTurnOff,
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (provider.isLoading && provider.albums.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.albums.isEmpty) {
      return Center(child: Text(t.noAlbums));
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200 &&
            !provider.isLoadingMore &&
            provider.hasMore) {
          provider.fetchAlbums();
        }
        return false;
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = getCrossAxisCount(constraints.maxWidth);
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 0.8,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: provider.albums.length + (provider.isLoadingMore ? 1 : 0),
            itemBuilder: (ctx, index) {
              if (index == provider.albums.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              final album = provider.albums[index];
              return AlbumGridItem(
                album: album,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AlbumDetailScreen(album: album),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}