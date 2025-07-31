import 'package:flutter/material.dart';

class VoiceButton extends StatefulWidget {
  final bool isListening;
  final bool isProcessing;
  final bool isSpeaking;
  final VoidCallback onTap;

  const VoiceButton({
    super.key,
    required this.isListening,
    required this.isProcessing,
    required this.isSpeaking,
    required this.onTap,
  });

  @override
  State<VoiceButton> createState() => _VoiceButtonState();
}

class _VoiceButtonState extends State<VoiceButton>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _rotateController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotateController,
      curve: Curves.linear,
    ));
  }

  @override
  void didUpdateWidget(VoiceButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isListening && !oldWidget.isListening) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isListening && oldWidget.isListening) {
      _pulseController.stop();
      _pulseController.reset();
    }
    
    if (widget.isProcessing && !oldWidget.isProcessing) {
      _rotateController.repeat();
    } else if (!widget.isProcessing && oldWidget.isProcessing) {
      _rotateController.stop();
      _rotateController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color buttonColor;
    IconData iconData;
    bool isAnimated = false;

    if (widget.isListening) {
      buttonColor = Colors.orange;
      iconData = Icons.mic;
      isAnimated = true;
    } else if (widget.isProcessing) {
      buttonColor = Colors.blue;
      iconData = Icons.sync;
      isAnimated = true;
    } else if (widget.isSpeaking) {
      buttonColor = Colors.green;
      iconData = Icons.volume_up;
      isAnimated = false;
    } else {
      buttonColor = const Color(0xFF4A90E2);
      iconData = Icons.mic;
      isAnimated = false;
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: isAnimated ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
        builder: (context, child) {
          return Transform.scale(
            scale: isAnimated ? _pulseAnimation.value : 1.0,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: buttonColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: buttonColor.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: AnimatedBuilder(
                animation: widget.isProcessing ? _rotateAnimation : const AlwaysStoppedAnimation(0.0),
                builder: (context, child) {
                  return Transform.rotate(
                    angle: widget.isProcessing ? _rotateAnimation.value * 2 * 3.14159 : 0.0,
                    child: Icon(
                      iconData,
                      size: 32,
                      color: Colors.white,
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
} 