import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/utils/logger.dart';
import '../../../domain/entities/university_entity.dart';

class UniversityImageCarousel extends StatelessWidget {
  final List<String> images;
  final UniversityEntity university;

  const UniversityImageCarousel({
    super.key,
    required this.images,
    required this.university,
  });

  @override
  Widget build(BuildContext context) {
    // لو مفيش صور خالص، نعرض placeholder شيك
    if (images.isEmpty) {
      return _buildPlaceholder();
    }

    return CarouselSlider(
      options: CarouselOptions(
        height: 300,
        viewportFraction: 1.0,
        autoPlay: images.length > 1,
      ),
      items: images.map((image) {
        return CachedNetworkImage(
          imageUrl: image, // ✅ مصلح: استخدم image مش university.logoUrl
          fit: BoxFit.cover,
          width: double.infinity,
          placeholder: (context, url) => const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          errorWidget: (context, url, error) {
            log.e('Carousel image error: $error');
            return _buildPlaceholder();
          },
        );
      }).toList(),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      color: Colors.grey[100],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_outlined, size: 50, color: Colors.grey[400]),
          SizedBox(height: 10.h),
          Text(
            'Image not available',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
