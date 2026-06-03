import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A widget that wraps the application in a realistic mobile device frame
/// when viewed on desktop web or large screens, ensuring a consistent mobile experience.
class PhoneFrame extends StatelessWidget {
  final Widget child;

  const PhoneFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    // If screen is narrow (mobile device size), render the app directly without frame.
    if (screenWidth <= 600) {
      return child;
    }

    // Phone dimensions
    const double phoneWidth = 390.0;
    const double phoneHeight = 844.0;
    const double borderRadius = 40.0;
    const double borderWidth = 12.0;

    // Handle vertical scaling for shorter displays
    final double targetHeight = phoneHeight + 60.0; // App height + padding
    final double scale = screenHeight < targetHeight
        ? (screenHeight / targetHeight) * 0.95
        : 1.0;

    // Inner dimensions of the simulated screen
    const double innerWidth = phoneWidth - (2 * borderWidth);
    const double innerHeight = phoneHeight - (2 * borderWidth);

    // Override the child's MediaQuery so it behaves exactly like a real mobile screen size.
    final mediaQueryData = MediaQuery.of(context);
    final simulatedMediaQuery = mediaQueryData.copyWith(
      size: const Size(innerWidth, innerHeight),
      padding: const EdgeInsets.only(top: 44, bottom: 34),
      viewPadding: const EdgeInsets.only(top: 44, bottom: 34),
      viewInsets: EdgeInsets.zero,
    );

    final Widget phoneBody = Container(
      width: phoneWidth,
      height: phoneHeight,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppColors.black, width: borderWidth),
        boxShadow: const [
          // Neo-brutalist offset solid shadows
          BoxShadow(
            color: AppColors.pitchGreen,
            offset: Offset(10, 10),
            blurRadius: 0,
          ),
          BoxShadow(
            color: AppColors.black,
            offset: Offset(14, 14),
            blurRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius - borderWidth),
        child: Stack(
          children: [
            // The actual application
            Positioned.fill(
              child: MediaQuery(data: simulatedMediaQuery, child: child),
            ),

            // Simulated Mobile Status Bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 44,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  color: Colors.transparent,
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '9:41',
                        style: TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          fontFamily: 'SpaceGrotesk',
                          letterSpacing: -0.2,
                        ),
                      ),
                      const Row(
                        children: [
                          Icon(
                            Icons.signal_cellular_4_bar,
                            color: AppColors.white,
                            size: 13,
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.wifi, color: AppColors.white, size: 13),
                          SizedBox(width: 4),
                          Icon(
                            Icons.battery_full,
                            color: AppColors.white,
                            size: 13,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Simulated Camera Notch (Dynamic Island style)
            Positioned(
              top: 8,
              left: (innerWidth - 110) / 2,
              child: IgnorePointer(
                child: Container(
                  width: 110,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.black,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.white.withValues(alpha: 0.08),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF151515),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Simulated iOS Home Indicator Bar
            Positioned(
              bottom: 8,
              left: (innerWidth - 140) / 2,
              child: IgnorePointer(
                child: Container(
                  width: 140,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.surfaceLow,
      body: Stack(
        children: [
          // Elegant Neo-Brutalist Dot Grid Canvas Background
          Positioned.fill(child: CustomPaint(painter: DotGridPainter())),

          // Header Title Panel
          Positioned(
            top: 30,
            left: 30,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.pitchGreen,
                    border: Border.all(color: AppColors.black, width: 3),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.black,
                        offset: Offset(4, 4),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: const Text(
                    'FLYBALL',
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontWeight: FontWeight.w900,
                      color: AppColors.black,
                      fontSize: 22,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Web Simulator',
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          // bottom instructions info card
          Positioned(
            bottom: 30,
            left: 30,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.black, width: 2.5),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.black,
                    offset: Offset(3, 3),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.devices, color: AppColors.pitchGreen, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Runs in native mobile layouts. Resize window down to test mobile direct view.',
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      color: AppColors.whiteMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Render phone screen body centered
          Center(
            child: scale == 1.0
                ? phoneBody
                : Transform.scale(scale: scale, child: phoneBody),
          ),
        ],
      ),
    );
  }
}

class DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.white.withValues(alpha: 0.035)
      ..strokeWidth = 2;

    const double spacing = 28.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
