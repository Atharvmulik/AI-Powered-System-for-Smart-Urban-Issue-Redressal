import 'package:flutter/material.dart';

class GuideOverlay extends StatefulWidget {
  final VoidCallback onFinish;

  const GuideOverlay({super.key, required this.onFinish});

  @override
  State<GuideOverlay> createState() => _GuideOverlayState();
}

class _GuideOverlayState extends State<GuideOverlay> {
  int _currentStep = 0;

  final List<GuideStep> _steps = [
    GuideStep(
      title: "Report Issue",
      description:
          "Here you can register your complaints like potholes, garbage, water issues etc.",
      left: 20,
      top: 500,
      width: 260,
    ),
    GuideStep(
      title: "Track Nearby Issues",
      description:
          "Check reported issues near you and stay informed about civic problems.",
      left: 20,
      top: 400,
      width: 260,
    ),
    GuideStep(
      title: "Profile",
      description: "View and edit your profile details here.",
      left: 190,
      top: 530,
      width: 200,
    ),
    GuideStep(
      title: "Reported Issues",
      description: "Here you can see all the complaints registered by you.",
      left: 100,
      top: 60,
      width: 250,
    ),
  ];

  void nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
    } else {
      widget.onFinish();
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];

    return Material(
      color: Colors.black54.withOpacity(0.7),
      child: Stack(
        children: [
          Positioned(
            left: step.left,
            top: step.top,
            child: _buildTooltip(step),
          ),
        ],
      ),
    );
  }

  Widget _buildTooltip(GuideStep step) {
    return CustomPaint(
      painter: SpeechBubblePainter(),
      child: Container(
        width: step.width,
        height: 250,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              step.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(step.description),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentStep > 0)
                  TextButton(
                    onPressed: previousStep,
                    child: const Text("Back"),
                  )
                else
                  const SizedBox(width: 64),
                ElevatedButton(
                  onPressed: nextStep,
                  child: Text(
                    _currentStep == _steps.length - 1 ? "Finish" : "Next",
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SpeechBubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();
    const radius = 12.0;
    const tailWidth = 20.0;
    const tailHeight = 20.0;

    // Rounded rectangle
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height - tailHeight),
      const Radius.circular(radius),
    ));

    // Tail centered at bottom
    final tailX = size.width / 2;
    path.moveTo(tailX - tailWidth / 2, size.height - tailHeight);
    path.lineTo(tailX, size.height);
    path.lineTo(tailX + tailWidth / 2, size.height - tailHeight);
    path.close();

    // Draw bubble
    canvas.drawShadow(path, Colors.black26, 4, true);
    canvas.drawPath(path, paint);

    // Border
    final borderPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate != this;
  }
}

class GuideStep {
  final String title;
  final String description;
  final double left;
  final double top;
  final double width;

  const GuideStep({
    required this.title,
    required this.description,
    required this.left,
    required this.top,
    required this.width,
  });
}