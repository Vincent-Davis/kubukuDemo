import 'dart:async';
import 'package:flutter/material.dart';

class CustomCarousel extends StatefulWidget {
  const CustomCarousel({super.key});

  @override
  _CustomCarouselState createState() => _CustomCarouselState();
}

class _CustomCarouselState extends State<CustomCarousel> {
  final PageController _pageController = PageController();
  final List<String> _images = [
    'assets/images/slider/1.png',
    'assets/images/slider/2.png',
    'assets/images/slider/3.png',
  ];
  int _currentIndex = 0;
  Timer? _autoPlayTimer;

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (_currentIndex < _images.length - 1) {
        _currentIndex++;
      } else {
        _currentIndex = 0;
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentIndex,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeIn,
        );
      }
    });
  }

  void _stopAutoPlay() {
    _autoPlayTimer?.cancel();
  }

  @override
  void dispose() {
    _stopAutoPlay();
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildIndicator() {
    return Positioned(
      bottom: 15,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: _images.asMap().entries.map((entry) {
          return GestureDetector(
            onTap: () => _pageController.animateToPage(
              entry.key,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeIn,
            ),
            child: Container(
              width: _currentIndex == entry.key ? 6.0 : 4.5,
              height: _currentIndex == entry.key ? 6.0 : 4.5,
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentIndex == entry.key
                  ? const Color(0xFF6D0CC9) 
                  : Colors.grey,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width; 
    final screenHeigth = MediaQuery.of(context).size.height; 
    return SizedBox(
      height: screenHeigth * 0.25,
      child: Stack(
        children: [
          GestureDetector(
            onPanDown: (_) => _stopAutoPlay(),
            onPanCancel: _startAutoPlay,
            onPanEnd: (_) => _startAutoPlay(),
            child: PageView.builder(
              controller: _pageController,
              itemCount: _images.length,
              onPageChanged: (int index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (BuildContext context, int index) {
                return Container(
                  width: screenWidth, 
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30.0),
                      topRight: Radius.circular(30.0),
                      ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30.0),
                      topRight: Radius.circular(30.0),
                      ),
                    child: Image.asset(
                      _images[index],
                      width: screenWidth,
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
          _buildIndicator(),
        ],
      ),
    );
  }
}
