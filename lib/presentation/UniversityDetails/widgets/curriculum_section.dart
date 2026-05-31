import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

class UniversityImageCarousel extends StatelessWidget {
  final List<String> images;
  const UniversityImageCarousel({super.key, required this.images});

  @override
  Widget build(BuildContext context) {
    return CarouselSlider(
      options: CarouselOptions(
        height: 300,
        viewportFraction: 1.0,
        autoPlay: true,
      ),
      items: images.map((image) {
        return Image.network(
          image,
          fit: BoxFit.cover,
          width: double.infinity,
          // 🔥 معالجة الخطأ هنا: لو الصورة مكسورة مش هيجيب X أحمر
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: double.infinity,
              color: const Color(0xFFF1F5F9), // خلفية رمادي هادية
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_balance,
                    size: 50,
                    color: Color(0xFFCBD5E1),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Image not available",
                    style: TextStyle(color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(child: CircularProgressIndicator());
          },
        );
      }).toList(),
    );
  }
}
