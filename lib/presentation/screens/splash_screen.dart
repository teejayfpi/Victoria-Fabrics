import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/particles.dart';

/// Branded launch screen for the customer app.
///
/// Emerald gradient, drifting particles, accent glows and a staggered brand
/// reveal, then hands off to the router once the auth state has settled.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  /// Minimum time the brand reveal stays visible. Short — it is launch latency.
  static const Duration _minDisplay = Duration(seconds: 2);

  bool _routed = false;
  bool _minDisplayElapsed = false;
  Timer? _minDisplayTimer;

  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _particlesController;
  late AnimationController _loadingController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _textOpacity;
  late Animation<double> _loadingOpacity;

  @override
  void initState() {
    super.initState();

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

    _particlesController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _loadingOpacity = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.easeInOut),
    );

    unawaited(_startAnimations());

    _minDisplayTimer = Timer(_minDisplay, () {
      if (!mounted) return;
      setState(() => _minDisplayElapsed = true);
    });
  }

  Future<void> _startAnimations() async {
    unawaited(_logoController.forward());
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    unawaited(_textController.forward());
  }

  @override
  void dispose() {
    _minDisplayTimer?.cancel();
    _logoController.dispose();
    _textController.dispose();
    _particlesController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  void _route() {
    if (_routed || !mounted) return;
    _routed = true;
    // The router redirect sends signed-out visitors to /signin, so home is
    // only ever reached with a session.
    final signedIn = ref.read(authStateProvider).valueOrNull != null;
    context.go(signedIn ? '/' : '/signin');
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
          // Background gradient
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
                color: Colors.white.withValues(alpha: 0.1),
              ),
              size: Size.infinite,
            ),
          ),

          // Accent glows
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
                    AppColors.accent.withValues(alpha: 0.3),
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
                    AppColors.primaryLight.withValues(alpha: 0.2),
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
                // device cannot fit the brand block.
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
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(32),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.2),
                                        blurRadius: 30,
                                        offset: const Offset(0, 15),
                                      ),
                                      BoxShadow(
                                        color:
                                            AppColors.accent.withValues(alpha: 0.3),
                                        blurRadius: 60,
                                        offset: const Offset(0, 30),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Container(
                                      width: 78,
                                      height: 78,
                                      decoration: BoxDecoration(
                                        gradient: AppColors.primaryGradient,
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      child: const Icon(
                                        Icons.diamond_rounded,
                                        size: 40,
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

                        // Brand name, tagline and feature pills
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
                                      AppConstants.appName,
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
                                  AppConstants.appTagline,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontWeight: FontWeight.w400,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 32),
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
                                      AppColors.accent,
                                    ),
                                    strokeWidth: 2.5,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Flexible(
                                  child: Text(
                                    _loadingLabel(auth),
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.9),
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
    if (!_minDisplayElapsed) return 'Welcome to ${AppConstants.appName}…';
    return 'Ready';
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
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
