import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/sign_model.dart';
import '../data/signs_database.dart';

/// Widget que muestra la seña seleccionada con su imagen y nombre.
/// Si no hay ninguna seleccionada, muestra un estado vacío amigable.
class SignViewerPanel extends StatelessWidget {
  /// La seña actualmente seleccionada; null si no hay ninguna.
  final SignModel? senaSeleccionada;

  const SignViewerPanel({
    super.key,
    required this.senaSeleccionada,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? const Color(0xFF0F0F1E) : const Color(0xFFEEF0FF),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: senaSeleccionada == null
            ? _EmptyViewer(key: const ValueKey('empty'), isDark: isDark)
            : _SignDisplay(
                key: ValueKey(senaSeleccionada!.id),
                sign: senaSeleccionada!,
                isDark: isDark,
              ),
      ),
    );
  }
}

// ─── Estado vacío ────────────────────────────────────────────────────────────

class _EmptyViewer extends StatelessWidget {
  final bool isDark;
  const _EmptyViewer({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ícono animado
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.white.withValues(alpha: 0.7),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.sign_language_outlined,
                size: 50,
                color: Color(0xFF6C63FF),
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  begin: const Offset(1.0, 1.0),
                  end: const Offset(1.05, 1.05),
                  duration: 2000.ms,
                  curve: Curves.easeInOut,
                ),

            const SizedBox(height: 28),

            Text(
              'Selecciona o busca\nuna palabra',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                height: 1.3,
                color: isDark ? Colors.white.withValues(alpha: 0.87) : const Color(0xFF1A1A2E),
              ),
            ),

            const SizedBox(height: 12),

            Text(
              'para ver su seña en\nLengua de Señas Peruana',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark ? Colors.white.withValues(alpha: 0.38) : Colors.black.withValues(alpha: 0.45),
                height: 1.5,
              ),
            ),

            const SizedBox(height: 32),

            // Tips rápidos
            _QuickTips(isDark: isDark),
          ],
        ),
      ),
    );
  }
}

class _QuickTips extends StatelessWidget {
  final bool isDark;
  const _QuickTips({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final tips = [
      (Icons.search_rounded, 'Busca por nombre'),
      (Icons.category_rounded, 'Filtra por categoría'),
      (Icons.touch_app_rounded, 'Toca para ver la seña'),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: tips.map((tip) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(tip.$1,
                  size: 14, color: const Color(0xFF6C63FF)),
              const SizedBox(width: 6),
              Text(
                tip.$2,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isDark ? Colors.white.withValues(alpha: 0.60) : Colors.black.withValues(alpha: 0.54),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─── Vista de seña seleccionada ──────────────────────────────────────────────

class _SignDisplay extends StatelessWidget {
  final SignModel sign;
  final bool isDark;

  const _SignDisplay({super.key, required this.sign, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = colorParaCategoria(sign.categoria);
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 700;

    // Tamaño del contenedor de imagen adaptativo
    final imageBoxSize = isWide
        ? (size.width * 0.38).clamp(220.0, 420.0)
        : (size.width * 0.72).clamp(180.0, 360.0);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Badge de categoría
            _CategoryBadge(sign: sign, color: color)
                .animate()
                .fadeIn(duration: 300.ms)
                .slideY(begin: -0.2, end: 0),

            const SizedBox(height: 24),

            // Contenedor de imagen principal
            _ImageContainer(
              sign: sign,
              color: color,
              size: imageBoxSize,
              isDark: isDark,
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 100.ms)
                .scale(
                  begin: const Offset(0.92, 0.92),
                  end: const Offset(1.0, 1.0),
                  curve: Curves.easeOutBack,
                ),

            const SizedBox(height: 28),

            // Nombre de la seña
            Text(
              sign.palabra,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: isWide ? 36 : 28,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                height: 1.1,
              ),
            )
                .animate()
                .fadeIn(duration: 350.ms, delay: 200.ms)
                .slideY(begin: 0.2, end: 0),

            const SizedBox(height: 8),

            // Subtítulo
            Text(
              'Lengua de Señas Peruana',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isDark ? Colors.white.withValues(alpha: 0.38) : Colors.black.withValues(alpha: 0.38),
                letterSpacing: 0.5,
              ),
            )
                .animate()
                .fadeIn(duration: 350.ms, delay: 280.ms),

            const SizedBox(height: 32),

            // Tarjeta de información
            _InfoCard(sign: sign, color: color, isDark: isDark)
                .animate()
                .fadeIn(duration: 400.ms, delay: 350.ms)
                .slideY(begin: 0.2, end: 0),
          ],
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final SignModel sign;
  final Color color;

  const _CategoryBadge({required this.sign, required this.color});

  @override
  Widget build(BuildContext context) {
    final icono = iconoParaCategoria(sign.categoria);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            sign.categoria,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageContainer extends StatelessWidget {
  final SignModel sign;
  final Color color;
  final double size;
  final bool isDark;

  const _ImageContainer({
    required this.sign,
    required this.color,
    required this.size,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 40,
            spreadRadius: 5,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Fondo con gradiente sutil
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.8,
                  colors: [
                    color.withValues(alpha: isDark ? 0.08 : 0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            // Imagen principal
            Image.asset(
              sign.pathImagen,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // Placeholder elegante si la imagen no existe
                return _ImagePlaceholder(sign: sign, color: color);
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Placeholder mostrado cuando la imagen del asset no existe todavía.
class _ImagePlaceholder extends StatelessWidget {
  final SignModel sign;
  final Color color;

  const _ImagePlaceholder({required this.sign, required this.color});

  @override
  Widget build(BuildContext context) {
    final icono = iconoParaCategoria(sign.categoria);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icono, size: 44, color: color.withValues(alpha: 0.7)),
        ),
        const SizedBox(height: 16),
        Text(
          sign.palabra,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Agrega la imagen en:\nassets/images/${sign.pathImagen.split('/').last}',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: Colors.black.withValues(alpha: 0.38),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final SignModel sign;
  final Color color;
  final bool isDark;

  const _InfoCard({
    required this.sign,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.10) : color.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _InfoItem(
              label: 'ID',
              value: sign.id,
              color: color,
              isDark: isDark,
            ),
          ),
          Container(width: 1, height: 40, color: isDark ? Colors.white.withValues(alpha: 0.10) : Colors.black.withValues(alpha: 0.08)),
          Expanded(
            child: _InfoItem(
              label: 'Categoría',
              value: sign.categoria,
              color: color,
              isDark: isDark,
            ),
          ),
          Container(width: 1, height: 40, color: isDark ? Colors.white.withValues(alpha: 0.10) : Colors.black.withValues(alpha: 0.08)),
          Expanded(
            child: _InfoItem(
              label: 'Idioma',
              value: 'LSP',
              color: color,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _InfoItem({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: isDark ? Colors.white.withValues(alpha: 0.38) : Colors.black.withValues(alpha: 0.38),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white.withValues(alpha: 0.87) : const Color(0xFF1A1A2E),
          ),
        ),
      ],
    );
  }
}
