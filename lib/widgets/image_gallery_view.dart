import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class ImageGalleryView extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const ImageGalleryView({super.key, required this.images, this.initialIndex = 0});

  @override
  State<ImageGalleryView> createState() => _ImageGalleryViewState();
}

class _ImageGalleryViewState extends State<ImageGalleryView> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Галерея
          PhotoViewGallery.builder(
            itemCount: widget.images.length,
            pageController: _pageController,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            backgroundDecoration: const BoxDecoration(color: Colors.transparent),
            builder: (context, index) => PhotoViewGalleryPageOptions(
              imageProvider: NetworkImage(widget.images[index]),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2,
            ),
          ),

          // Счётчик
          Positioned(
            top: 60,
            child: Text(
              "${_currentIndex + 1} / ${widget.images.length}",
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),

          // Кнопка закрытия
          Positioned(
            top: 50,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Стрелки (показываем только если картинок больше одной)
          if (widget.images.length > 1) ...[
            if (_currentIndex > 0)
              Positioned(
                left: 10,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
                  onPressed: () => _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                ),
              ),
            if (_currentIndex < widget.images.length - 1)
              Positioned(
                right: 10,
                child: IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, color: Colors.white70),
                  onPressed: () =>
                      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
