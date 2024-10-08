import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'pixabay_api.dart';

void main() {
  runApp(const ImageGalleryApp());
}

class ImageGalleryApp extends StatelessWidget {
  const ImageGalleryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Gallery',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ImageGalleryPage(),
    );
  }
}

class ImageGalleryPage extends StatefulWidget {
  const ImageGalleryPage({super.key});

  @override
  _ImageGalleryPageState createState() => _ImageGalleryPageState();
}

class _ImageGalleryPageState extends State<ImageGalleryPage> {
  final PixabayApi _pixabayApi = PixabayApi();
  final PagingController<int, dynamic> _pagingController =
      PagingController(firstPageKey: 1);

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final newImages = await _pixabayApi.fetchImages(pageKey);
      final isLastPage = newImages.length < 20;
      if (isLastPage) {
        _pagingController.appendLastPage(newImages);
      } else {
        final nextPageKey = pageKey + 1;
        _pagingController.appendPage(newImages, nextPageKey);
      }
    } catch (error) {
      _pagingController.error = error;
    }
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Gallery'),
      ),
      body: PagedGridView<int, dynamic>(
        pagingController: _pagingController,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: (MediaQuery.of(context).size.width / 150).floor(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.7,
        ),
        padding: const EdgeInsets.all(8),
        builderDelegate: PagedChildBuilderDelegate<dynamic>(
          itemBuilder: (context, item, index) {
            return GestureDetector(
              onTap: () {
                // Navigate to full-screen image page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FullScreenImagePage(
                      imageUrl: item['webformatURL'],
                      likes: item['likes'],
                      views: item['views'],
                    ),
                  ),
                );
              },
              child: Column(
                children: [
                  Expanded(
                    child: Image.network(
                      item['webformatURL'],
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Likes: ${item['likes']}'),
                  Text('Views: ${item['views']}'),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// Full-screen image page
class FullScreenImagePage extends StatelessWidget {
  final String imageUrl;
  final int likes;
  final int views;

  const FullScreenImagePage({
    required this.imageUrl,
    required this.likes,
    required this.views,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Full-Screen Image'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text('Likes: $likes'),
                Text('Views: $views'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Go back to the gallery page
                  },
                  child: const Text('Back to Gallery'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
