import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'connect_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Controllers
  late AnimationController _nodeController;
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _pulseController;
  late AnimationController _exitController;

  // Node network animations
  late Animation<double> _node1Anim;
  late Animation<double> _node2Anim;
  late Animation<double> _node3Anim;
  late Animation<double> _node4Anim;
  late Animation<double> _lineAnim;

  // Logo animations
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;

  // Text animations
  late Animation<double> _titleOpacity;
  late Animation<Offset> _titleSlide;
  late Animation<double> _taglineOpacity;

  // Pulse (idle glow)
  late Animation<double> _pulse;

  // Exit
  late Animation<double> _exitOpacity;

  @override
  void initState() {
    super.initState();

    // --- Node network appears (0–900ms) ---
    _nodeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _node1Anim = CurvedAnimation(
      parent: _nodeController,
      curve: const Interval(0.0, 0.4, curve: Curves.elasticOut),
    );
    _node2Anim = CurvedAnimation(
      parent: _nodeController,
      curve: const Interval(0.15, 0.55, curve: Curves.elasticOut),
    );
    _node3Anim = CurvedAnimation(
      parent: _nodeController,
      curve: const Interval(0.3, 0.7, curve: Curves.elasticOut),
    );
    _node4Anim = CurvedAnimation(
      parent: _nodeController,
      curve: const Interval(0.45, 0.85, curve: Curves.elasticOut),
    );
    _lineAnim = CurvedAnimation(
      parent: _nodeController,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
    );

    // --- Logo pop-in (600–1200ms) ---
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _logoController,
          curve: const Interval(0.0, 0.4, curve: Curves.easeOut)),
    );

    // --- Text fade+slide in (1000–1600ms) ---
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _textController,
          curve: const Interval(0.0, 0.6, curve: Curves.easeOut)),
    );
    _titleSlide =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _textController,
          curve: const Interval(0.4, 1.0, curve: Curves.easeOut)),
    );

    // --- Idle pulse loop ---
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // --- Exit fade out ---
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeIn),
    );

    _runSequence();
  }

  Future<void> _runSequence() async {
    // Nodes appear
    await Future.delayed(const Duration(milliseconds: 200));
    _nodeController.forward();

    // Logo pops in
    await Future.delayed(const Duration(milliseconds: 600));
    _logoController.forward();

    // Text slides in
    await Future.delayed(const Duration(milliseconds: 400));
    _textController.forward();

    // Hold
    await Future.delayed(const Duration(milliseconds: 1400));

    // Exit
    _exitController.forward();
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const ConnectScreen(),
        transitionDuration: Duration.zero,
      ),
    );
  }

  @override
  void dispose() {
    _nodeController.dispose();
    _logoController.dispose();
    _textController.dispose();
    _pulseController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: AnimatedBuilder(
        animation: _exitOpacity,
        builder: (context, child) => Opacity(
          opacity: _exitOpacity.value,
          child: child,
        ),
        child: Stack(
          children: [
            // Background gradient
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.2),
                  radius: 1.0,
                  colors: [Color(0xFF12082A), Color(0xFF0A0A0F)],
                ),
              ),
            ),

            // Node network canvas
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _nodeController,
                builder: (_, __) => CustomPaint(
                  painter: _NodeNetworkPainter(
                    node1Progress: _node1Anim.value,
                    node2Progress: _node2Anim.value,
                    node3Progress: _node3Anim.value,
                    node4Progress: _node4Anim.value,
                    lineProgress: _lineAnim.value,
                    pulseValue: _pulse.value,
                    size: size,
                  ),
                ),
              ),
            ),

            // Center content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo icon
                  AnimatedBuilder(
                    animation: _logoController,
                    builder: (_, __) => Opacity(
                      opacity: _logoOpacity.value,
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: AnimatedBuilder(
                          animation: _pulseController,
                          builder: (_, child) => Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(26),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00F5C4), Color(0xFF7C3AED)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00F5C4)
                                      .withOpacity(0.25 * _pulse.value),
                                  blurRadius: 40,
                                  spreadRadius: 8,
                                ),
                                BoxShadow(
                                  color: const Color(0xFF7C3AED)
                                      .withOpacity(0.2 * _pulse.value),
                                  blurRadius: 30,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: _NodiIcon(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // App name + tagline
                  AnimatedBuilder(
                    animation: _textController,
                    builder: (_, __) => FadeTransition(
                      opacity: _titleOpacity,
                      child: SlideTransition(
                        position: _titleSlide,
                        child: Column(
                          children: [
                            // NODI wordmark
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _GlowLetter(
                                    letter: 'N',
                                    color: const Color(0xFF00F5C4),
                                    pulse: _pulse),
                                _GlowLetter(
                                    letter: 'O',
                                    color: Colors.white,
                                    pulse: _pulse),
                                _GlowLetter(
                                    letter: 'D',
                                    color: Colors.white,
                                    pulse: _pulse),
                                _GlowLetter(
                                    letter: 'I',
                                    color: const Color(0xFF7C3AED),
                                    pulse: _pulse),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // Tagline
                            FadeTransition(
                              opacity: _taglineOpacity,
                              child: Text(
                                'connect · relay · communicate',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.35),
                                  letterSpacing: 2.5,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom version text
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _textController,
                builder: (_, __) => FadeTransition(
                  opacity: _taglineOpacity,
                  child: Text(
                    'v1.0.0',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.15),
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Nodi logo icon (node-dot pattern) ───────────────────────────────────────
class _NodiIcon extends StatelessWidget {
  const _NodiIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(48, 48),
      painter: _NodiLogoPainter(),
    );
  }
}

class _NodiLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final linePaint = Paint()
      ..color = Colors.black.withOpacity(0.7)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final nodePaint = Paint()..color = Colors.black;

    // Node positions (pentagon-ish)
    final nodes = [
      Offset(cx, cy - 16), // top
      Offset(cx + 16, cy - 4), // right-top
      Offset(cx + 10, cy + 13), // right-bottom
      Offset(cx - 10, cy + 13), // left-bottom
      Offset(cx - 16, cy - 4), // left-top
    ];

    // Draw connecting lines
    final connections = [
      [0, 1],
      [1, 2],
      [2, 3],
      [3, 4],
      [4, 0],
      [0, 2],
      [1, 3],
    ];
    for (final c in connections) {
      canvas.drawLine(nodes[c[0]], nodes[c[1]], linePaint);
    }

    // Draw nodes
    for (final n in nodes) {
      canvas.drawCircle(n, 3.5, nodePaint);
    }

    // Center node
    canvas.drawCircle(Offset(cx, cy), 3, nodePaint..color = Colors.black);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─── Glowing letter widget ────────────────────────────────────────────────────
class _GlowLetter extends StatelessWidget {
  final String letter;
  final Color color;
  final Animation<double> pulse;

  const _GlowLetter({
    required this.letter,
    required this.color,
    required this.pulse,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (_, __) => Text(
        letter,
        style: TextStyle(
          fontSize: 52,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: -1,
          shadows: color != Colors.white
              ? [
                  Shadow(
                    color: color.withOpacity(0.6 * pulse.value),
                    blurRadius: 20,
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}

// ─── Background node network painter ─────────────────────────────────────────
class _NodeNetworkPainter extends CustomPainter {
  final double node1Progress;
  final double node2Progress;
  final double node3Progress;
  final double node4Progress;
  final double lineProgress;
  final double pulseValue;
  final Size size;

  _NodeNetworkPainter({
    required this.node1Progress,
    required this.node2Progress,
    required this.node3Progress,
    required this.node4Progress,
    required this.lineProgress,
    required this.pulseValue,
    required this.size,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final w = size.width;
    final h = size.height;

    // Background nodes (decorative, around the edges)
    final bgNodes = [
      Offset(w * 0.12, h * 0.18),
      Offset(w * 0.88, h * 0.22),
      Offset(w * 0.08, h * 0.72),
      Offset(w * 0.92, h * 0.68),
      Offset(w * 0.25, h * 0.88),
      Offset(w * 0.75, h * 0.85),
      Offset(w * 0.5, h * 0.12),
    ];

    final progresses = [
      node1Progress,
      node2Progress,
      node3Progress,
      node4Progress,
      node1Progress * 0.8,
      node2Progress * 0.7,
      node3Progress * 0.9,
    ];

    // Draw connecting lines between bg nodes
    final linePaint = Paint()
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round;

    final lineConnections = [
      [0, 6],
      [6, 1],
      [0, 2],
      [1, 3],
      [2, 4],
      [3, 5],
      [4, 5]
    ];

    for (int i = 0; i < lineConnections.length; i++) {
      final a = bgNodes[lineConnections[i][0]];
      final b = bgNodes[lineConnections[i][1]];
      final prog =
          (progresses[lineConnections[i][0]] * lineProgress).clamp(0.0, 1.0);

      if (prog <= 0) continue;

      final endX = a.dx + (b.dx - a.dx) * prog;
      final endY = a.dy + (b.dy - a.dy) * prog;

      linePaint.color = const Color(0xFF00F5C4).withOpacity(0.08 * pulseValue);
      canvas.drawLine(a, Offset(endX, endY), linePaint);
    }

    // Draw bg nodes
    final nodePaint = Paint();
    for (int i = 0; i < bgNodes.length; i++) {
      final p = progresses[i].clamp(0.0, 1.0);
      if (p <= 0) continue;

      final node = bgNodes[i];
      final radius = 3.0 * p;

      // Glow
      nodePaint.color =
          const Color(0xFF00F5C4).withOpacity(0.08 * p * pulseValue);
      nodePaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(node, radius * 3, nodePaint);

      // Core
      nodePaint.color = const Color(0xFF00F5C4).withOpacity(0.3 * p);
      nodePaint.maskFilter = null;
      canvas.drawCircle(node, radius, nodePaint);
    }
  }

  @override
  bool shouldRepaint(_NodeNetworkPainter old) =>
      old.node1Progress != node1Progress ||
      old.lineProgress != lineProgress ||
      old.pulseValue != pulseValue;
}
