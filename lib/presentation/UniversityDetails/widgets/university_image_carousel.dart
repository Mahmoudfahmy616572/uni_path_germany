import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../data/models/university_model.dart';

class UniversityImageCarousel extends StatelessWidget {
  final List<String> images;
  final UniversityModel university;

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
          imageUrl: university.logoUrl ?? '', // لو الـ URL null هيتبعت فاضي
          fit: BoxFit.cover,
          width: double.infinity,
          // لما الصورة بتحمل
          // استبدل الجزء الخاص بالـ placeholder والـ errorWidget بـ:
          placeholder: (context, url) => const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          errorWidget: (context, url, error) {
            print(
              "Error loading image: $error",
            ); // بص على الـ Debug Console لما الصورة تفشل
            return const Icon(Icons.broken_image, color: Colors.grey);
          },
        );
      }).toList(),
    );
  }

  // ده شكل الـ Placeholder الشيك لما الصورة تغيب أو تفشل
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
            "Image not available",
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
