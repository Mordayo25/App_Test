import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../data/signs_database.dart';
import '../services/error_bag_service.dart';

/// Pantalla de inicio principal con acceso a Vocabulario, Práctica y Quiz.
class HomeScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const HomeScreen({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen> {
  final _bag = ErrorBagService.instance;

  @override
  void initState() {
    super.initState();
    _bag.addListener(_onBagChanged);
  }

  @override
  void dispose() {
    _bag.removeListener(_onBagChanged);
    super.dispose();
  }

  void _onBagChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F0F1E) : const Color(0xFFEEF0FF);


    return Scaffold(
      backgroundColor: bg,
      appBar: _buildAppBar(context, isDark),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 700;
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 60 : 24,
                vertical: 40,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeroSection(isDark: isDark, isWide: isWide),
                    const SizedBox(height: 48),
                    _StatsRow(isDark: isDark),
                    // Bolsa de errores (solo visible si hay errores)
                    if (_bag.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _ErrorBagBanner(count: _bag.count, isDark: isDark),
                    ],
                    const SizedBox(height: 40),
                    _SectionLabel(label: 'Módulos de aprendizaje', isDark: isDark),
                    const SizedBox(height: 20),
                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _ModuleCard.vocabulario(context, isDark)),
                          const SizedBox(width: 20),
                          Expanded(child: _ModuleCard.practica(context, isDark)),
                          const SizedBox(width: 20),
                          Expanded(child: _ModuleCard.quiz(context, isDark)),
                        ],
                      )
                    else ...[
                      _ModuleCard.vocabulario(context, isDark),
                      const SizedBox(height: 16),
                      _ModuleCard.practica(context, isDark),
                      const SizedBox(height: 16),
                      _ModuleCard.quiz(context, isDark),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDark) {
    return AppBar(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      title: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/images/logo.jpg',
              width: 32,
              height: 32,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'MaxiSeñas LSP',
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: widget.onToggleTheme,
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Icon(
              widget.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              key: ValueKey(widget.isDarkMode),
              color: isDark
                  ? Colors.white.withValues(alpha: 0.60)
                  : Colors.black.withValues(alpha: 0.54),
              size: 20,
            ),
          ),
          tooltip: widget.isDarkMode ? 'Modo claro' : 'Modo oscuro',
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(
          height: 1,
          thickness: 1,
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.08),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero Section
// ─────────────────────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  final bool isDark;
  final bool isWide;

  const _HeroSection({required this.isDark, required this.isWide});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF6C63FF).withValues(alpha: 0.20),
                const Color(0xFF48CAE4).withValues(alpha: 0.20),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF6C63FF).withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, size: 13, color: Color(0xFF6C63FF)),
              const SizedBox(width: 6),
              Text(
                'Lengua de Señas Peruana',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6C63FF),
                ),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 400.ms)
            .slideX(begin: -0.1, end: 0),

        const SizedBox(height: 20),

        // Título principal
        Text(
          'Aprende LSP\nde forma interactiva',
          style: GoogleFonts.inter(
            fontSize: isWide ? 44 : 32,
            fontWeight: FontWeight.w800,
            height: 1.15,
            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
          ),
        )
            .animate()
            .fadeIn(duration: 500.ms, delay: 100.ms)
            .slideY(begin: 0.1, end: 0),

        const SizedBox(height: 14),

        Text(
          'Explora vocabulario completo, pon a prueba tus\nconocimientos o lánzate a un Quiz Rápido sin pistas.',
          style: GoogleFonts.inter(
            fontSize: isWide ? 17 : 15,
            color: isDark
                ? Colors.white.withValues(alpha: 0.55)
                : Colors.black.withValues(alpha: 0.50),
            height: 1.6,
          ),
        )
            .animate()
            .fadeIn(duration: 500.ms, delay: 200.ms),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats Row
// ─────────────────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final bool isDark;
  const _StatsRow({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cats = categorias.where((c) => c != 'Todas').length;

    final stats = [
      (signsDatabase.length.toString(), 'Señas totales', Icons.sign_language),
      (cats.toString(), 'Categorías', Icons.category_rounded),
      ('10', 'Por práctica', Icons.quiz_rounded),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: List.generate(stats.length, (i) {
        final s = stats[i];
        return _StatChip(
          value: s.$1,
          label: s.$2,
          icon: s.$3,
          isDark: isDark,
        ).animate().fadeIn(duration: 400.ms, delay: (200 + i * 80).ms).slideY(begin: 0.15, end: 0);
      }),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final bool isDark;

  const _StatChip({
    required this.value,
    required this.label,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.black.withValues(alpha: 0.07),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF6C63FF)),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.40)
                      : Colors.black.withValues(alpha: 0.42),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Label
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;

  const _SectionLabel({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: isDark
            ? Colors.white.withValues(alpha: 0.38)
            : Colors.black.withValues(alpha: 0.40),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 350.ms);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Module Card
// ─────────────────────────────────────────────────────────────────────────────

class _ModuleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;
  final Color colorEnd;
  final String route;
  final bool isDark;
  final List<String> features;
  final int animDelay;

  const _ModuleCard({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
    required this.colorEnd,
    required this.route,
    required this.isDark,
    required this.features,
    required this.animDelay,
  });

  factory _ModuleCard.vocabulario(BuildContext context, bool isDark) {
    return _ModuleCard(
      title: 'Vocabulario',
      subtitle: 'Explorador de señas',
      description:
          'Navega por todas las categorías, busca palabras y visualiza cada seña con su imagen en alta resolución.',
      icon: Icons.menu_book_rounded,
      color: const Color(0xFF6C63FF),
      colorEnd: const Color(0xFF48CAE4),
      route: '/vocabulario',
      isDark: isDark,
      features: const ['Búsqueda inteligente', 'Filtro por categoría', 'Imágenes HD'],
      animDelay: 400,
    );
  }

  factory _ModuleCard.practica(BuildContext context, bool isDark) {
    return _ModuleCard(
      title: 'Práctica',
      subtitle: 'Aprendizaje interactivo',
      description:
          'Estudia 10 señas, luego pon a prueba tu memoria con un quiz de alternativas y recibe tu puntaje final.',
      icon: Icons.quiz_rounded,
      color: const Color(0xFFFF6B6B),
      colorEnd: const Color(0xFFFFBF69),
      route: '/practica',
      isDark: isDark,
      features: const ['Estudio guiado', 'Quiz interactivo', 'Resultados y puntaje'],
      animDelay: 500,
    );
  }

  factory _ModuleCard.quiz(BuildContext context, bool isDark) {
    return _ModuleCard(
      title: 'Quiz Rápido',
      subtitle: 'Pon a prueba tu memoria',
      description:
          'Sin estudiar antes: ve directamente al quiz. Elige categorías y demuestra cuánto sabes de LSP.',
      icon: Icons.bolt_rounded,
      color: const Color(0xFFFFBF69),
      colorEnd: const Color(0xFFFF6B6B),
      route: '/quiz',
      isDark: isDark,
      features: const ['Sin pistas previas', 'Categorías a elegir', 'Modo desafío'],
      animDelay: 600,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.white.withValues(alpha: 0.90),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: color.withValues(alpha: isDark ? 0.25 : 0.18),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.12),
                blurRadius: 30,
                offset: const Offset(0, 8),
              ),
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ícono con gradiente
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, colorEnd],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),

                const SizedBox(height: 20),

                // Subtítulo
                Text(
                  subtitle.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: color,
                  ),
                ),
                const SizedBox(height: 6),

                // Título
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),

                const SizedBox(height: 10),

                // Descripción
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 1.6,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.52)
                        : Colors.black.withValues(alpha: 0.50),
                  ),
                ),

                const SizedBox(height: 20),

                // Features chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: features.map((f) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        f,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // CTA Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, route),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Abrir $title',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_rounded, size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: animDelay.ms)
        .slideY(begin: 0.1, end: 0);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error Bag Banner
// ─────────────────────────────────────────────────────────────────────────────

/// Banner que aparece en el home cuando hay señas pendientes de refuerzo.
class _ErrorBagBanner extends StatelessWidget {
  final int count;
  final bool isDark;

  const _ErrorBagBanner({required this.count, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/repaso'),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF4CAF50).withValues(alpha: isDark ? 0.18 : 0.12),
                const Color(0xFF00BCD4).withValues(alpha: isDark ? 0.12 : 0.08),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.40),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Ícono con badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.recycling_rounded,
                        color: Color(0xFF4CAF50), size: 24),
                  ),
                  Positioned(
                    top: -6,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B6B),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: isDark
                                ? const Color(0xFF0F0F1E)
                                : const Color(0xFFEEF0FF),
                            width: 1.5),
                      ),
                      child: Text(
                        '$count',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 14),

              // Texto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Repasar errores recientes',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$count ${count == 1 ? 'seña pendiente' : 'señas pendientes'} de refuerzo',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.55)
                            : Colors.black.withValues(alpha: 0.50),
                      ),
                    ),
                  ],
                ),
              ),

              // Flecha
              const Icon(
                Icons.arrow_forward_rounded,
                color: Color(0xFF4CAF50),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.08, end: 0);
  }
}
