import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';

class SosHoldButton extends StatefulWidget {
  final VoidCallback onSosTriggered;
  final bool isDark;

  const SosHoldButton({
    super.key,
    required this.onSosTriggered,
    this.isDark = false,
  });

  @override
  State<SosHoldButton> createState() => _SosHoldButtonState();
}

class _SosHoldButtonState extends State<SosHoldButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isHolding = false;
  Timer? _holdTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _isHolding = false;
        widget.onSosTriggered();
        _controller.reset();
      }
    });
  }

  void _startHolding() {
    setState(() {
      _isHolding = true;
    });
    _controller.forward(from: 0.0);
  }

  void _cancelHolding() {
    if (_isHolding) {
      setState(() {
        _isHolding = false;
      });
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _holdTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _startHolding(),
      onTapUp: (_) => _cancelHolding(),
      onTapCancel: () => _cancelHolding(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final progress = _controller.value;
          final remainingSeconds = (3.0 * (1.0 - progress)).ceil();

          return Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: CityRideTheme.errorColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: CityRideTheme.errorColor.withOpacity(_isHolding ? 0.5 : 0.25),
                  blurRadius: _isHolding ? 14 : 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Progress Bar Overlay
                if (_isHolding)
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: progress,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF991B1B),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),

                // Button Content
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.sos_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          _isHolding
                              ? "HOLDING FOR SOS\n(${remainingSeconds}s remaining)"
                              : "PRESS & HOLD\nEMERGENCY SOS (3s)",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.2,
                            height: 1.15,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
