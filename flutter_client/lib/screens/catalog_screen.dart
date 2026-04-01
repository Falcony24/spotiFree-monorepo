import 'package:flutter/material.dart';
import 'package:frontend/widgets/album_grid_item.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/albums_provider.dart';
import 'package:frontend/screens/album_detail_screen.dart';
import 'package:frontend/utils/responsive.dart';

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
      Provider.of<AlbumsProvider>(context, listen: false).fetchAlbums(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AlbumsProvider>(context);

    if (provider.isLoading && provider.albums.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.albums.isEmpty) {
      return const Center(child: Text('Brak albumów do wyświetlenia'));
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