import 'dart:math' as math;
import 'package:flutter/material.dart';

class ConfettiOverlay extends StatefulWidget {
  final Widget child;
  final bool showConfetti;

  const ConfettiOverlay({
    Key? key,
    required this.child,
    required this.showConfetti,
  }) : super(key: key);

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<ConfettiParticle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _controller.addListener(() {
      _updateParticles();
      setState(() {});
    });

    if (widget.showConfetti) {
      _startConfetti();
    }
  }

  @override
  void didUpdateWidget(ConfettiOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showConfetti && !oldWidget.showConfetti) {
      _startConfetti();
    } else if (!widget.showConfetti && oldWidget.showConfetti) {
      _controller.stop();
      _particles.clear();
    }
  }

  void _startConfetti() {
    _particles.clear();
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.pink,
      Colors.orange,
      Colors.purple,
      Colors.teal,
    ];

    for (int i = 0; i < 120; i++) {
      _particles.add(ConfettiParticle(
        relativeX: _random.nextDouble(),
        y: -_random.nextDouble() * 200 - 20,
        vx: (_random.nextDouble() - 0.5) * 4,
        vy: _random.nextDouble() * 5 + 3,
        color: colors[_random.nextInt(colors.length)],
        size: _random.nextDouble() * 6 + 6,
        rotation: _random.nextDouble() * 2 * math.pi,
        rotationSpeed: (_random.nextDouble() - 0.5) * 0.2,
        shape: _random.nextBool() ? ParticleShape.rectangle : ParticleShape.circle,
      ));
    }
    _controller.forward(from: 0.0);
  }

  void _updateParticles() {
    for (var particle in _particles) {
      particle.vy += 0.15;
      particle.vx *= 0.98;
      particle.y += particle.vy;
      particle.rotation += particle.rotationSpeed;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.showConfetti && _particles.isNotEmpty)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: ConfettiPainter(
                  particles: _particles,
                  animationValue: _controller.value,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

enum ParticleShape { circle, rectangle }

class ConfettiParticle {
  double relativeX;
  double? absoluteX;
  double y;
  double vx;
  double vy;
  Color color;
  double size;
  double rotation;
  double rotationSpeed;
  ParticleShape shape;

  ConfettiParticle({
    required this.relativeX,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
    required this.shape,
  });
}

class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  final double animationValue;

  ConfettiPainter({required this.particles, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var p in particles) {
      if (p.absoluteX == null) {
        p.absoluteX = p.relativeX * size.width;
      }
      p.absoluteX = (p.absoluteX! + p.vx) % size.width;

      if (p.y > size.height) continue;

      paint.color = p.color;

      canvas.save();
      canvas.translate(p.absoluteX!, p.y);
      canvas.rotate(p.rotation);

      if (p.shape == ParticleShape.circle) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size * 1.5,
            height: p.size,
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
