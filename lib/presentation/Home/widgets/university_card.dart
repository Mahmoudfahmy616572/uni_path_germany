import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UniversityCard extends StatelessWidget {
  final String logoText;
  final String name;
  final String program;
  final int matchPercentage;

  const UniversityCard({
    super.key,
    required this.logoText,
    required this.name,
    required this.program,
    required this.matchPercentage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // University Logo Placeholder
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(logoText, style: GoogleFonts.poppins(color: const Color(0xFF5A67D8), fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 16),
          // University Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF1A202C))),
                    ),
                    Text("$matchPercentage% Match", style: GoogleFonts.poppins(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(program, style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 13)),
                const SizedBox(height: 12),
                // Tags
                Row(
                  children: [
                    _buildTag("No IELTS"),
                    const SizedBox(width: 8),
                    _buildTag("English Program"),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFF5A67D8), fontWeight: FontWeight.w500)),
    );
  }
}