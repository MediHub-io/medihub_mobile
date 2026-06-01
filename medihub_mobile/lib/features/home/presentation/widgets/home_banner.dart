import 'package:flutter/material.dart';

class HomeBanner
    extends StatelessWidget {

  const HomeBanner({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(16),
        gradient:
            const LinearGradient(
          colors: [
            Color(0xFF00B4A6),
            Color(0xFF00897B),
          ],
        ),
      ),
      child: const Center(
        child: Text(
          'MediHub Healthcare',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),
    );
  }
}