import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

// --- 1. Particle Data Model (Stores unique movement properties) ---
class FloatingParticle {
  final String id;
  final Widget icon;
  final double startX;
  final double startY;
  final double endX;
  final double endY;
  final Duration duration;
  final double size;
  final double randomFactor;
  final DateTime createdAt; // Track when particle was created
  final double speedMultiplier; // Individual speed variation
  final double driftAmplitude; // Random drift amplitude for each particle

  const FloatingParticle({
    required this.id,
    required this.icon,
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    required this.duration,
    required this.size,
    required this.randomFactor, // Used for unique horizontal sway
    required this.createdAt,
    required this.speedMultiplier,
    required this.driftAmplitude,
  });
}

// --- 2. Floating Emitter Widget ---
class FloatingEmitter extends StatefulWidget {
  final List<String> assetPaths;
  final Duration emissionInterval;
  final Duration particleDuration;
  final double particleSizeMin;
  final double particleSizeMax;
  final int maxParticles;

  const FloatingEmitter({
    super.key,
    required this.assetPaths,
    this.emissionInterval =
        const Duration(milliseconds: 400), // Slightly slower emission
    this.particleDuration =
        const Duration(seconds: 25), // Longer lifespan for slower feel
    this.particleSizeMin = 35.0,
    this.particleSizeMax = 60.0,
    this.maxParticles = 25,
  });

  @override
  State<FloatingEmitter> createState() => _FloatingEmitterState();
}

class _FloatingEmitterState extends State<FloatingEmitter>
    with TickerProviderStateMixin {
  final List<FloatingParticle> _particles = [];
  late Ticker _updateTicker;
  late Ticker _emissionTicker;
  final Random _random = Random();
  Duration _lastEmission = Duration.zero;
  Duration _nextEmissionInterval =
      Duration.zero; // Randomized emission interval

  @override
  void initState() {
    super.initState();

    // Ticker to update all particles based on their individual progress
    _updateTicker = Ticker((elapsed) {
      if (mounted) {
        setState(() {
          // Remove particles that have exceeded their duration
          final now = DateTime.now();
          _particles.removeWhere((p) {
            final age = now.difference(p.createdAt);
            return age >= p.duration;
          });
        });
      }
    });
    _updateTicker.start();

    // Calculate initial random emission interval
    _nextEmissionInterval = Duration(
      milliseconds: (widget.emissionInterval.inMilliseconds *
              (0.4 + _random.nextDouble() * 1.2))
          .round(), // 40% to 160% of base interval
    );

    // Separate ticker for particle emission with randomized intervals
    _emissionTicker = Ticker((elapsed) {
      if (elapsed - _lastEmission >= _nextEmissionInterval && mounted) {
        _lastEmission = elapsed;
        // Calculate next random interval for more natural variation
        _nextEmissionInterval = Duration(
          milliseconds: (widget.emissionInterval.inMilliseconds *
                  (0.4 + _random.nextDouble() * 1.2))
              .round(),
        );
        _emitParticle();
      }
    });
    _emissionTicker.start();
  }

  // Check if a position would collide with existing particles
  bool _wouldCollide(double x, double y, double size,
      List<FloatingParticle> existingParticles) {
    final minDistance =
        size * 1.5; // Minimum distance between particles (1.5x their size)
    final now = DateTime.now();

    for (final particle in existingParticles) {
      final age = now.difference(particle.createdAt);
      if (age >= particle.duration) continue; // Skip expired particles

      // Calculate particle's current position
      final progress = (age.inMilliseconds / particle.duration.inMilliseconds)
          .clamp(0.0, 1.0);
      final particleX =
          particle.startX + (particle.endX - particle.startX) * progress;
      final particleY =
          particle.startY + (particle.endY - particle.startY) * progress;

      // Calculate distance between centers
      final distance = sqrt(pow(x - particleX, 2) + pow(y - particleY, 2));

      // Check if too close (collision)
      if (distance < (size / 2 + particle.size / 2 + minDistance)) {
        return true;
      }
    }
    return false;
  }

  void _emitParticle() {
    if (widget.assetPaths.isEmpty || _particles.length >= widget.maxParticles) {
      return;
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final particleSize = widget.particleSizeMin +
        _random.nextDouble() *
            (widget.particleSizeMax - widget.particleSizeMin);

    // Try to find a non-colliding position (max 10 attempts)
    double startX = 0, startY = 0, endX = 0, endY = 0;
    bool foundValidPosition = false;

    for (int attempt = 0; attempt < 10; attempt++) {
      // --- 1. DETERMINE STARTING EDGE (0=Top, 1=Right, 2=Bottom, 3=Left) ---
      final int startSide = _random.nextInt(4);

      // --- 2. CALCULATE RANDOM START/END POSITIONS WITH MORE VARIATION ---
      // Add curved paths and more randomness
      final curveOffset =
          (_random.nextDouble() - 0.5) * screenWidth * 0.3; // Random curve

      switch (startSide) {
        case 0: // TOP -> Moves diagonally toward Bottom/Random
          startX = _random.nextDouble() * screenWidth;
          startY = -particleSize - 50.0;
          endX = (_random.nextDouble() * screenWidth + curveOffset)
              .clamp(0.0, screenWidth);
          endY = screenHeight + 50.0 + (_random.nextDouble() * 100 - 50);
          break;
        case 1: // RIGHT -> Moves diagonally toward Left/Random
          startX = screenWidth + 50.0;
          startY = _random.nextDouble() * screenHeight;
          endX = -particleSize - 50.0 - (_random.nextDouble() * 50);
          endY = (_random.nextDouble() * screenHeight + curveOffset)
              .clamp(0.0, screenHeight);
          break;
        case 2: // BOTTOM -> Moves diagonally toward Top/Random
          startX = _random.nextDouble() * screenWidth;
          startY = screenHeight + 50.0;
          endX = (_random.nextDouble() * screenWidth + curveOffset)
              .clamp(0.0, screenWidth);
          endY = -particleSize - 50.0 - (_random.nextDouble() * 50);
          break;
        case 3: // LEFT -> Moves diagonally toward Right/Random
          startX = -particleSize - 50.0;
          startY = _random.nextDouble() * screenHeight;
          endX = screenWidth + 50.0 + (_random.nextDouble() * 50);
          endY = (_random.nextDouble() * screenHeight + curveOffset)
              .clamp(0.0, screenHeight);
          break;
      }

      // Check if start position collides with existing particles
      if (!_wouldCollide(startX, startY, particleSize, _particles)) {
        foundValidPosition = true;
        break;
      }
    }

    // If we couldn't find a valid position after 10 attempts, skip this emission
    if (!foundValidPosition) {
      return;
    }

    final randomAssetPath =
        widget.assetPaths[_random.nextInt(widget.assetPaths.length)];

    // More randomized speed multiplier (0.4x to 1.8x for greater variation)
    final speedMultiplier = 0.4 + _random.nextDouble() * 1.4;

    // Calculate actual duration with additional randomness
    // Add random variation to duration (80% to 120% of calculated duration)
    final baseDuration = widget.particleDuration.inMilliseconds;
    final calculatedDuration = (baseDuration / speedMultiplier).round();
    final durationVariation = 0.8 + _random.nextDouble() * 0.4; // 80% to 120%
    final actualDuration = Duration(
      milliseconds: (calculatedDuration * durationVariation).round(),
    );

    // Build the icon widget using Image.asset
    final iconWidget = Image.asset(
      randomAssetPath,
      width: particleSize,
      height: particleSize,
      errorBuilder: (context, error, stackTrace) {
        // Return empty widget if asset fails to load (prevents error messages)
        return const SizedBox.shrink();
      },
    );

    // Random drift amplitude for each particle (25-45 pixels)
    final driftAmplitude = 25.0 + _random.nextDouble() * 20.0;

    _particles.add(
      FloatingParticle(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        icon: iconWidget,
        startX: startX,
        startY: startY,
        endX: endX,
        endY: endY,
        duration: actualDuration,
        size: particleSize,
        randomFactor: 0.2 +
            _random.nextDouble() *
                1.2, // 0.2 to 1.4 for more variation in drift
        createdAt: DateTime.now(),
        speedMultiplier: speedMultiplier,
        driftAmplitude: driftAmplitude,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Stack(
      children: _particles.map((particle) {
        // Calculate individual progress for each particle (0.0 to 1.0)
        final age = now.difference(particle.createdAt);
        final progress = (age.inMilliseconds / particle.duration.inMilliseconds)
            .clamp(0.0, 1.0);

        // 1. Vertical Movement (Interpolated between StartY and EndY)
        final double currentY =
            particle.startY + (particle.endY - particle.startY) * progress;

        // 2. Horizontal Movement (Interpolated between StartX and EndX)
        final double straightX =
            particle.startX + (particle.endX - particle.startX) * progress;

        // 3. Horizontal Oscillation (Random Sway with natural drift)
        // Multiple sine waves for more complex, natural movement
        final double driftFactor1 =
            sin(progress * pi * 2 * particle.randomFactor);
        final double driftFactor2 =
            sin(progress * pi * 2 * particle.randomFactor * 1.7 + pi / 3);
        final double combinedDrift = (driftFactor1 * 0.6 + driftFactor2 * 0.4);
        final double currentX =
            straightX + (combinedDrift * particle.driftAmplitude);

        // 4. Opacity with smooth fade in and fade out
        // Fade in during first 12% of animation, fade out during last 18%
        double opacity;
        if (progress < 0.12) {
          // Fade in: 0.0 -> 1.0 over first 12%
          opacity = (progress / 0.12).clamp(0.0, 1.0);
        } else if (progress > 0.82) {
          // Fade out: 1.0 -> 0.0 over last 18%
          opacity = ((1.0 - progress) / 0.18).clamp(0.0, 1.0);
        } else {
          // Full opacity in the middle
          opacity = 1.0;
        }

        return Positioned(
          key: ValueKey(particle.id),
          left: currentX, // Use the oscillating X position
          top: currentY,
          child: Opacity(
            opacity: opacity,
            child: particle.icon,
          ),
        );
      }).toList(),
    );
  }

  @override
  void dispose() {
    _updateTicker.dispose();
    _emissionTicker.dispose();
    super.dispose();
  }
}
