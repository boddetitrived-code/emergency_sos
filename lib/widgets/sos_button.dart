import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class SosButton extends StatefulWidget {
  final VoidCallback onTap;
  final double size;

  const SosButton({
    super.key,
    required this.onTap,
    this.size = 170.0,
  });

  @override
  State<SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<SosButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: child,
        );
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.sosRed.withOpacity(0.35),
              blurRadius: 28,
              spreadRadius: 6,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            customBorder: const CircleBorder(),
            splashColor: Colors.white30,
            highlightColor: Colors.white10,
            child: Ink(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  center: Alignment(-0.2, -0.3),
                  radius: 0.95,
                  colors: [
                    Color(0xFFEF4444),
                    Color(0xFFDC2626),
                    Color(0xFF991B1B),
                  ],
                  stops: [0.0, 0.6, 1.0],
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 3.5,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'SOS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                        height: 1.0,
                        shadows: [
                          Shadow(
                            color: Colors.black45,
                            offset: Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'PRESS FOR HELP',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
