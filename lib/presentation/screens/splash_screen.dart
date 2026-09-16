import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';

/// Enterprise splash screen.
///
/// Layers the store hero photograph behind an emerald scrim, animated
/// particles and brand reveal, then hands off to the router once the auth
/// state has settled.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  /// Minimum time the splash stays visible so the brand reveal is seen.
  /// Keep this short — every millisecond here is launch latency.
  static const Duration _minDisplay = Duration(seconds: 2);

  bool _routed = false;
  bool _minDisplayElapsed = false;
  Timer? _minDisplayTimer;

  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _particlesController;
  late AnimationController _loadingController;
  late AnimationController _heroController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _textOpacity;
  late Animation<double> _loadingOpacity;
  late Animation<double> _heroScale;

  @override
  void initState() {
    super.initState();

    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );
    _heroScale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _heroController, curve: Curves.easeOut),
    );
    _heroController.forward();

    // Logo animation
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    // Text animation
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );

    // Particles animation
    _particlesController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Loading animation
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _loadingOpacity = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.easeInOut),
    );

    _startAnimations();

    _minDisplayTimer = Timer(_minDisplay, () {
      if (!mounted) return;
      setState(() => _minDisplayElapsed = true);
    });
  }

  void _startAnimations() async {
    _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    _textController.forward();
  }

  @override
  void dispose() {
    _minDisplayTimer?.cancel();
    _logoController.dispose();
    _textController.dispose();
    _particlesController.dispose();
    _loadingController.dispose();
    _heroController.dispose();
    super.dispose();
  }

  void _route() {
    if (_routed || !mounted) return;
    _routed = true;
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);

    if (_minDisplayElapsed && auth.hasValue) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _route());
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Store hero photograph
          AnimatedBuilder(
            animation: _heroScale,
            builder: (context, child) => Transform.scale(
              scale: _heroScale.value,
              child: child,
            ),
            child: Image.asset(
              'assets/images/splash.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const ColoredBox(color: AppColors.primaryDark),
            ),
          ),

          // Fallback gradient behind transparent parts of the artwork
          const DecoratedBox(
            decoration: BoxDecoration(gradient: AppColors.heroGradient),
            child: SizedBox.expand(),
          ),

          // Animated particles
          AnimatedBuilder(
            animation: _particlesController,
            builder: (context, child) => CustomPaint(
              painter: ParticlesPainter(
                progress: _particlesController.value,
                color: Colors.white.withOpacity(0.1),
              ),
              size: Size.infinite,
            ),
          ),

          // Accent glow
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accent.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primaryLight.withOpacity(0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Gradient scrim so overlaid text stays readable
          const DecoratedBox(
            decoration: BoxDecoration(gradient: AppColors.splashScrim),
            child: SizedBox.expand(),
          ),

          // Main content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                // Bottom-anchored when there is room, scrollable when a short
                // or narrow device cannot fit the brand block.
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 28, 28, 48),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Logo badge
                        Center(
                          child: AnimatedBuilder(
                            animation: _logoController,
                            builder: (context, child) => Opacity(
                              opacity: _logoOpacity.value,
                              child: Transform.scale(
                                scale: _logoScale.value,
                                child: Container(
                                  width: 112,
                                  height: 112,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(30),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 30,
                                        offset: const Offset(0, 15),
                                      ),
                                      BoxShadow(
                                        color:
                                            AppColors.accent.withOpacity(0.3),
                                        blurRadius: 60,
                                        offset: const Offset(0, 30),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Container(
                                      width: 72,
                                      height: 72,
                                      decoration: BoxDecoration(
                                        gradient: AppColors.primaryGradient,
                                        borderRadius: BorderRadius.circular(22),
                                      ),
                                      child: const Icon(
                                        Icons.diamond_rounded,
                                        size: 36,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Brand name and tagline
                        SlideTransition(
                          position: _textSlide,
                          child: FadeTransition(
                            opacity: _textOpacity,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 60,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    gradient: AppColors.accentGradient,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                ShaderMask(
                                  shaderCallback: (bounds) =>
                                      const LinearGradient(
                                    colors: [Colors.white, Color(0xFFFFD54F)],
                                  ).createShader(bounds),
                                  child: const FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Victoria Fabrics',
                                      style: TextStyle(
                                        fontSize: 42,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: -1,
                                        height: 1.1,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                Text(
                                  'Premium Ankara, Lace & Cotton, delivered.',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white.withOpacity(0.9),
                                    fontWeight: FontWeight.w400,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 32),

                                // Feature pills
                                const Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: [
                                    _FeaturePill(
                                      icon: Icons.palette_rounded,
                                      label: 'Handpicked Prints',
                                    ),
                                    _FeaturePill(
                                      icon: Icons.verified_rounded,
                                      label: 'Quality Assured',
                                    ),
                                    _FeaturePill(
                                      icon: Icons.local_shipping_rounded,
                                      label: 'Fast Delivery',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Loading indicator
                        AnimatedBuilder(
                          animation: _loadingOpacity,
                          builder: (context, child) => Opacity(
                            opacity: _loadingOpacity.value,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation(
                                        AppColors.accent),
                                    strokeWidth: 2.5,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Flexible(
                                  child: Text(
                                    _loadingLabel(auth),
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
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
        ],
      ),
    );
  }

  String _loadingLabel(AsyncValue<Object?> auth) {
    if (_routed) return 'Opening…';
    if (auth.isLoading) return 'Starting up…';
    if (!_minDisplayElapsed) return 'Welcome to Victoria Fabrics…';
    return 'Ready';
  }
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeaturePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for the drifting background particles.
class ParticlesPainter extends CustomPainter {
  final double progress;
  final Color color;

  ParticlesPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Seeded so the particle field is stable across repaints.
    final random = math.Random(42);

    for (int i = 0; i < 30; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 3 + 1;
      final speed = random.nextDouble() * 0.5 + 0.1;
      final angle = random.nextDouble() * math.pi * 2;

      final offset = Offset(
        x + math.sin(angle + progress * 2) * 20 * speed,
        y -
            progress * size.height * speed * 0.3 +
            math.cos(angle + progress * 2) * 15 * speed,
      );

      paint.color = color.withOpacity(0.3 + random.nextDouble() * 0.4);
      canvas.drawCircle(offset, radius, paint);
    }
  }

  @override
  bool shouldRepaint(ParticlesPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
