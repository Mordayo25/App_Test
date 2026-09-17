import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../data/signs_database.dart';
import '../models/sign_model.dart';
import '../services/error_bag_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Constantes
// ─────────────────────────────────────────────────────────────────────────────

const int _kPracticeCount = 10;
const int _kOptionsCount = 3;

/// Enumeración de las fases del flujo de práctica.
/// Enumeración de las fases del flujo de práctica.
enum _PracticePhase { setup, study, quiz, results }

// ─────────────────────────────────────────────────────────────────────────────
// PracticeScreen
// ─────────────────────────────────────────────────────────────────────────────

/// Pantalla de práctica interactiva con 4 fases:
///   0. Selección → elige categorías a practicar.
///   1. Estudio   → tarjetas con imagen + texto.
///   2. Quiz      → imagen sola + 3 botones de alternativa.
///   3. Resultados → puntaje y opciones de replay.
class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  // ── Estado global ────────────────────────────────────────────────────────────
  _PracticePhase _phase = _PracticePhase.setup;
  late List<SignModel> _practiceSet;
  int _currentIndex = 0;
  int _score = 0;

  // Selección de categorías (vacío = todas)
  Set<String> _selectedCategories = {};

  // Estado quiz
  List<SignModel>? _currentOptions;
  SignModel? _selectedOption;
  bool _answered = false;

  // Todas las categorías disponibles en la BD
  late final List<String> _allCategories;

  @override
  void initState() {
    super.initState();
    final seen = <String>{};
    _allCategories = signsDatabase
        .map((s) => s.categoria)
        .where(seen.add)
        .toList()
      ..sort();
    _practiceSet = [];
  }

  /// Vuelve a la pantalla de selección de categorías.
  void _goToSetup() {
    setState(() {
      _phase = _PracticePhase.setup;
    });
  }

  /// Arranca la sesión con las categorías seleccionadas (o todas si ninguna).
  void _startPractice() {
    final rng = Random();
    final pool = _selectedCategories.isEmpty
        ? signsDatabase
        : signsDatabase
            .where((s) => _selectedCategories.contains(s.categoria))
            .toList();
    final shuffled = List<SignModel>.from(pool)..shuffle(rng);
    setState(() {
      _practiceSet = shuffled.take(_kPracticeCount).toList();
      _phase = _PracticePhase.study;
      _currentIndex = 0;
      _score = 0;
      _selectedOption = null;
      _answered = false;
      _currentOptions = null;
    });
  }

  // ── Handlers Estudio ─────────────────────────────────────────────────────────

  void _nextStudyCard() {
    if (_currentIndex < _practiceSet.length - 1) {
      setState(() => _currentIndex++);
    } else {
      setState(() {
        _phase = _PracticePhase.quiz;
        _currentIndex = 0;
        _currentOptions = _buildOptions(_practiceSet[0]);
      });
    }
  }

  // ── Helpers Quiz ─────────────────────────────────────────────────────────────

  List<SignModel> _buildOptions(SignModel correct) {
    final rng = Random();
    const needed = _kOptionsCount - 1;

    // 1. Buscar distractores de la MISMA categoría (excluye la correcta y las
    //    que ya están en el set de práctica si es posible).
    final sameCategory = signsDatabase
        .where((s) => s.id != correct.id && s.categoria == correct.categoria)
        .toList()
      ..shuffle(rng);

    final List<SignModel> picked = sameCategory.take(needed).toList();

    // 2. Si no hay suficientes de la misma categoría, completar con otras
    //    categorías (pero siempre distintas entre sí y distintas a la correcta).
    if (picked.length < needed) {
      final usedIds = {correct.id, ...picked.map((s) => s.id)};
      final fallback = signsDatabase
          .where((s) => !usedIds.contains(s.id))
          .toList()
        ..shuffle(rng);
      picked.addAll(fallback.take(needed - picked.length));
    }

    final options = [correct, ...picked]..shuffle(rng);
    return options;
  }

  void _selectOption(SignModel option) {
    if (_answered) return;
    final correct = _practiceSet[_currentIndex];
    setState(() {
      _selectedOption = option;
      _answered = true;
      if (option.id == correct.id) {
        _score++;
      } else {
        // Registrar error en la bolsa de refuerzo
        ErrorBagService.instance.addError(correct.id);
      }
    });
  }

  void _nextQuizCard() {
    if (_currentIndex < _practiceSet.length - 1) {
      final nextIndex = _currentIndex + 1;
      setState(() {
        _currentIndex = nextIndex;
        _selectedOption = null;
        _answered = false;
        _currentOptions = _buildOptions(_practiceSet[nextIndex]);
      });
    } else {
      setState(() => _phase = _PracticePhase.results);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F0F1E) : const Color(0xFFEEF0FF),
      appBar: _buildAppBar(context, isDark),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.05, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: switch (_phase) {
            _PracticePhase.setup => _SetupPhase(
                key: const ValueKey('setup'),
                allCategories: _allCategories,
                selectedCategories: _selectedCategories,
                isDark: isDark,
                onToggleCategory: (cat) => setState(() {
                  if (_selectedCategories.contains(cat)) {
                    _selectedCategories.remove(cat);
                  } else {
                    _selectedCategories.add(cat);
                  }
                }),
                onClearAll: () =>
                    setState(() => _selectedCategories = {}),
                onStart: _startPractice,
              ),
            _PracticePhase.study => _StudyPhase(
                key: ValueKey('study-$_currentIndex'),
                sign: _practiceSet[_currentIndex],
                index: _currentIndex,
                total: _practiceSet.length,
                isDark: isDark,
                onNext: _nextStudyCard,
              ),
            _PracticePhase.quiz => _QuizPhase(
                key: ValueKey('quiz-$_currentIndex-$_answered'),
                sign: _practiceSet[_currentIndex],
                options: _currentOptions ?? [],
                index: _currentIndex,
                total: _practiceSet.length,
                score: _score,
                selectedOption: _selectedOption,
                answered: _answered,
                isDark: isDark,
                onSelect: _selectOption,
                onNext: _nextQuizCard,
              ),
            _PracticePhase.results => _ResultsPhase(
                key: const ValueKey('results'),
                score: _score,
                total: _practiceSet.length,
                isDark: isDark,
                onRepeat: _goToSetup,
                onHome: () => Navigator.pop(context),
              ),
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDark) {
    final phaseLabel = switch (_phase) {
      _PracticePhase.setup => 'Configurar',
      _PracticePhase.study => 'Estudio',
      _PracticePhase.quiz => 'Quiz',
      _PracticePhase.results => 'Resultados',
    };

    return AppBar(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(
          Icons.arrow_back_rounded,
          color: isDark
              ? Colors.white.withValues(alpha: 0.80)
              : const Color(0xFF1A1A2E),
        ),
        tooltip: 'Volver al inicio',
      ),
      title: Row(
        children: [
          const Icon(Icons.quiz_rounded, color: Color(0xFFFF6B6B), size: 20),
          const SizedBox(width: 8),
          Text(
            'Práctica · $phaseLabel',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            ),
          ),
        ],
      ),
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
// Fase 0: Selección de categorías
// ─────────────────────────────────────────────────────────────────────────────

class _SetupPhase extends StatelessWidget {
  final List<String> allCategories;
  final Set<String> selectedCategories;
  final bool isDark;
  final ValueChanged<String> onToggleCategory;
  final VoidCallback onClearAll;
  final VoidCallback onStart;

  const _SetupPhase({
    super.key,
    required this.allCategories,
    required this.selectedCategories,
    required this.isDark,
    required this.onToggleCategory,
    required this.onClearAll,
    required this.onStart,
  });

  bool get _isAllSelected => selectedCategories.isEmpty;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Cabecera ────────────────────────────────────────────────────
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFFFF6B6B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6C63FF).withValues(alpha: 0.35),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '¿Qué quieres practicar?',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Elige una o más categorías, o practica con todo el vocabulario.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        height: 1.5,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.50)
                            : Colors.black.withValues(alpha: 0.48),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 350.ms).slideY(begin: -0.08, end: 0),

              const SizedBox(height: 28),

              // ── Opción: Todas las señas ─────────────────────────────────────
              _ModeCard(
                icon: Icons.shuffle_rounded,
                title: 'Aleatorio · Todas las señas',
                subtitle: '${signsDatabase.length} señas de todas las categorías',
                isSelected: _isAllSelected,
                accentColor: const Color(0xFF6C63FF),
                isDark: isDark,
                onTap: onClearAll,
              ).animate().fadeIn(duration: 350.ms, delay: 60.ms),

              const SizedBox(height: 20),

              // ── Etiqueta categorías ─────────────────────────────────────────
              Row(
                children: [
                  Text(
                    'O elige categorías específicas',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.40)
                          : Colors.black.withValues(alpha: 0.40),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Divider(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.10)
                          : Colors.black.withValues(alpha: 0.08),
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 350.ms, delay: 100.ms),

              const SizedBox(height: 12),

              // ── Chips de categorías ─────────────────────────────────────────
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: allCategories.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final cat = entry.value;
                  final isSelected =
                      !_isAllSelected && selectedCategories.contains(cat);
                  final color = colorParaCategoria(cat);
                  final icon = iconoParaCategoria(cat);
                  final count =
                      signsDatabase.where((s) => s.categoria == cat).length;

                  return GestureDetector(
                    onTap: () => onToggleCategory(cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withValues(alpha: 0.18)
                            : isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.black.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? color.withValues(alpha: 0.70)
                              : isDark
                                  ? Colors.white.withValues(alpha: 0.10)
                                  : Colors.black.withValues(alpha: 0.10),
                          width: isSelected ? 1.8 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon,
                              size: 15,
                              color: isSelected
                                  ? color
                                  : isDark
                                      ? Colors.white.withValues(alpha: 0.55)
                                      : Colors.black.withValues(alpha: 0.45)),
                          const SizedBox(width: 6),
                          Text(
                            cat,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? color
                                  : isDark
                                      ? Colors.white.withValues(alpha: 0.75)
                                      : Colors.black.withValues(alpha: 0.65),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? color.withValues(alpha: 0.20)
                                  : isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : Colors.black.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$count',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? color
                                    : isDark
                                        ? Colors.white.withValues(alpha: 0.45)
                                        : Colors.black.withValues(alpha: 0.40),
                              ),
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 4),
                            Icon(Icons.check_circle_rounded,
                                size: 14, color: color),
                          ],
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(
                            duration: 300.ms,
                            delay: Duration(milliseconds: 120 + idx * 30))
                        .scale(
                            begin: const Offset(0.90, 0.90),
                            end: const Offset(1, 1)),
                  );
                }).toList(),
              ),

              const SizedBox(height: 32),

              // ── Botón Comenzar ──────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onStart,
                  icon: const Icon(Icons.play_arrow_rounded, size: 22),
                  label: Text(
                    _isAllSelected
                        ? 'Comenzar (todas las señas)'
                        : selectedCategories.length == 1
                            ? 'Comenzar · ${selectedCategories.first}'
                            : 'Comenzar · ${selectedCategories.length} categorías',
                    style: GoogleFonts.inter(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: 350.ms, delay: 200.ms)
                  .slideY(begin: 0.1, end: 0),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widget: tarjeta de modo (Todas / Categoría)
// ─────────────────────────────────────────────────────────────────────────────

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final Color accentColor;
  final bool isDark;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.accentColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.12)
              : isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? accentColor.withValues(alpha: 0.65)
                : isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : Colors.black.withValues(alpha: 0.08),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.18),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: isSelected ? 0.20 : 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon,
                  color: accentColor.withValues(alpha: isSelected ? 1.0 : 0.65),
                  size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? accentColor
                          : isDark
                              ? Colors.white.withValues(alpha: 0.88)
                              : const Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.42)
                          : Colors.black.withValues(alpha: 0.42),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded,
                  color: accentColor, size: 22)
            else
              Icon(Icons.radio_button_unchecked_rounded,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.25)
                      : Colors.black.withValues(alpha: 0.20),
                  size: 22),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Fase 1: Estudio
// ─────────────────────────────────────────────────────────────────────────────

class _StudyPhase extends StatelessWidget {
  final SignModel sign;
  final int index;
  final int total;
  final bool isDark;
  final VoidCallback onNext;

  const _StudyPhase({
    super.key,
    required this.sign,
    required this.index,
    required this.total,
    required this.isDark,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final color = colorParaCategoria(sign.categoria);
    final isLast = index == total - 1;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Progreso
              _ProgressHeader(
                label: 'Estudio',
                index: index,
                total: total,
                color: const Color(0xFF6C63FF),
                isDark: isDark,
              ),

              const SizedBox(height: 28),

              // Tarjeta principal
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1A1A2E)
                      : Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: color.withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.15),
                      blurRadius: 40,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    children: [
                      // Badge categoría
                      _CategoryPill(sign: sign, color: color),
                      const SizedBox(height: 24),

                      // Imagen
                      _SignImage(sign: sign, color: color, isDark: isDark, size: 260),
                      const SizedBox(height: 24),

                      // Palabra
                      Text(
                        sign.palabra,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        sign.categoria,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.38)
                              : Colors.black.withValues(alpha: 0.38),
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: 350.ms)
                  .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),

              const SizedBox(height: 28),

              // Botón siguiente
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onNext,
                  icon: Icon(
                    isLast ? Icons.quiz_rounded : Icons.arrow_forward_rounded,
                    size: 18,
                  ),
                  label: Text(
                    isLast ? 'Comenzar Quiz' : 'Siguiente (${index + 1}/$total)',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isLast ? const Color(0xFFFF6B6B) : const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Fase 2: Quiz
// ─────────────────────────────────────────────────────────────────────────────

class _QuizPhase extends StatelessWidget {
  final SignModel sign;
  final List<SignModel> options;
  final int index;
  final int total;
  final int score;
  final SignModel? selectedOption;
  final bool answered;
  final bool isDark;
  final ValueChanged<SignModel> onSelect;
  final VoidCallback onNext;

  const _QuizPhase({
    super.key,
    required this.sign,
    required this.options,
    required this.index,
    required this.total,
    required this.score,
    required this.selectedOption,
    required this.answered,
    required this.isDark,
    required this.onSelect,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final color = colorParaCategoria(sign.categoria);
    final isLast = index == total - 1;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Progreso + score
              _ProgressHeader(
                label: 'Quiz',
                index: index,
                total: total,
                color: const Color(0xFFFF6B6B),
                isDark: isDark,
                trailing: Text(
                  '$score / $total',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFFF6B6B),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Pregunta
              Text(
                '¿Cuál es esta seña?',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),

              const SizedBox(height: 20),

              // Imagen (sin texto)
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1A1A2E)
                      : Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: color.withValues(alpha: 0.20),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.15),
                      blurRadius: 30,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: _SignImage(sign: sign, color: color, isDark: isDark, size: 220),
              )
                  .animate()
                  .fadeIn(duration: 300.ms)
                  .scale(begin: const Offset(0.94, 0.94), end: const Offset(1, 1)),

              const SizedBox(height: 24),

              // Opciones
              ...List.generate(options.length, (i) {
                final opt = options[i];
                final isCorrect = opt.id == sign.id;
                final isSelected = selectedOption?.id == opt.id;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _OptionButton(
                    option: opt,
                    isCorrect: isCorrect,
                    isSelected: isSelected,
                    answered: answered,
                    isDark: isDark,
                    onTap: () => onSelect(opt),
                    animDelay: i * 60,
                  ),
                );
              }),

              // Feedback
              if (answered) ...[
                const SizedBox(height: 8),
                _FeedbackBanner(
                  isCorrect: selectedOption?.id == sign.id,
                  correctWord: sign.palabra,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onNext,
                    icon: Icon(
                      isLast ? Icons.emoji_events_rounded : Icons.arrow_forward_rounded,
                      size: 18,
                    ),
                    label: Text(
                      isLast ? 'Ver resultados' : 'Siguiente',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLast
                          ? const Color(0xFFFFBF69)
                          : const Color(0xFF6C63FF),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Fase 3: Resultados
// ─────────────────────────────────────────────────────────────────────────────

class _ResultsPhase extends StatelessWidget {
  final int score;
  final int total;
  final bool isDark;
  final VoidCallback onRepeat;
  final VoidCallback onHome;

  const _ResultsPhase({
    super.key,
    required this.score,
    required this.total,
    required this.isDark,
    required this.onRepeat,
    required this.onHome,
  });

  String get _emoji {
    final pct = score / total;
    if (pct == 1.0) return '🏆';
    if (pct >= 0.8) return '🎉';
    if (pct >= 0.6) return '👍';
    if (pct >= 0.4) return '💪';
    return '📚';
  }

  String get _message {
    final pct = score / total;
    if (pct == 1.0) return '¡Perfecto! Dominas estas señas.';
    if (pct >= 0.8) return '¡Excelente trabajo! Casi lo logras.';
    if (pct >= 0.6) return '¡Buen esfuerzo! Sigue practicando.';
    if (pct >= 0.4) return 'Vas progresando. ¡No te rindas!';
    return 'Repasa el vocabulario y vuelve a intentarlo.';
  }

  Color get _scoreColor {
    final pct = score / total;
    if (pct >= 0.8) return const Color(0xFF4CAF50);
    if (pct >= 0.5) return const Color(0xFFFFBF69);
    return const Color(0xFFFF6B6B);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Emoji trofeo
              Text(
                _emoji,
                style: const TextStyle(fontSize: 80),
              )
                  .animate()
                  .scale(begin: const Offset(0.3, 0.3), end: const Offset(1, 1),
                      curve: Curves.elasticOut, duration: 800.ms)
                  .fadeIn(duration: 400.ms),

              const SizedBox(height: 24),

              // Puntaje
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 28),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1A1A2E)
                      : Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: _scoreColor.withValues(alpha: 0.30),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _scoreColor.withValues(alpha: 0.20),
                      blurRadius: 40,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'PUNTAJE FINAL',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.38)
                            : Colors.black.withValues(alpha: 0.38),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$score',
                          style: GoogleFonts.inter(
                            fontSize: 72,
                            fontWeight: FontWeight.w900,
                            color: _scoreColor,
                            height: 1,
                          ),
                        ),
                        Text(
                          ' / $total',
                          style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.38)
                                : Colors.black.withValues(alpha: 0.38),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Barra de progreso
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: score / total,
                        minHeight: 8,
                        backgroundColor: isDark
                            ? Colors.white.withValues(alpha: 0.10)
                            : Colors.black.withValues(alpha: 0.08),
                        valueColor: AlwaysStoppedAnimation(_scoreColor),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _message,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        height: 1.5,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.70)
                            : Colors.black.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(duration: 500.ms, delay: 300.ms)
                  .slideY(begin: 0.15, end: 0),

              const SizedBox(height: 32),

              // Botones
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onRepeat,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(
                    'Repetir Práctica',
                    style: GoogleFonts.inter(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 500.ms)
                  .slideY(begin: 0.1, end: 0),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onHome,
                  icon: const Icon(Icons.home_rounded, size: 18),
                  label: Text(
                    'Volver al Inicio',
                    style: GoogleFonts.inter(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.80)
                        : const Color(0xFF1A1A2E),
                    side: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.20)
                          : Colors.black.withValues(alpha: 0.15),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 600.ms)
                  .slideY(begin: 0.1, end: 0),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Subwidgets compartidos
// ─────────────────────────────────────────────────────────────────────────────

/// Cabecera con barra de progreso y etiqueta de fase.
class _ProgressHeader extends StatelessWidget {
  final String label;
  final int index;
  final int total;
  final Color color;
  final bool isDark;
  final Widget? trailing;

  const _ProgressHeader({
    required this.label,
    required this.index,
    required this.total,
    required this.color,
    required this.isDark,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$label · ${index + 1} de $total',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.50)
                    : Colors.black.withValues(alpha: 0.50),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: (index + 1) / total),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            builder: (_, value, __) => LinearProgressIndicator(
              value: value,
              minHeight: 6,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.10)
                  : Colors.black.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
      ],
    );
  }
}

/// Imagen de la seña con placeholder si no existe.
class _SignImage extends StatelessWidget {
  final SignModel sign;
  final Color color;
  final bool isDark;
  final double size;

  const _SignImage({
    required this.sign,
    required this.color,
    required this.isDark,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0F0F1E)
            : const Color(0xFFF4F4F8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Image.asset(
          sign.pathImagen,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(iconoParaCategoria(sign.categoria),
                    size: 52, color: color.withValues(alpha: 0.5)),
                const SizedBox(height: 8),
                Text(
                  sign.palabra,
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Chip pequeño con nombre de categoría.
class _CategoryPill extends StatelessWidget {
  final SignModel sign;
  final Color color;

  const _CategoryPill({required this.sign, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconoParaCategoria(sign.categoria), size: 13, color: color),
          const SizedBox(width: 6),
          Text(
            sign.categoria,
            style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}

/// Botón de opción para el quiz con feedback visual.
class _OptionButton extends StatelessWidget {
  final SignModel option;
  final bool isCorrect;
  final bool isSelected;
  final bool answered;
  final bool isDark;
  final VoidCallback onTap;
  final int animDelay;

  const _OptionButton({
    required this.option,
    required this.isCorrect,
    required this.isSelected,
    required this.answered,
    required this.isDark,
    required this.onTap,
    required this.animDelay,
  });

  @override
  Widget build(BuildContext context) {
    // Colores de estado
    Color borderColor;
    Color bgColor;
    Color textColor;
    IconData? trailingIcon;

    if (!answered) {
      borderColor = isDark
          ? Colors.white.withValues(alpha: 0.15)
          : Colors.black.withValues(alpha: 0.12);
      bgColor = isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.white.withValues(alpha: 0.90);
      textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
      trailingIcon = null;
    } else if (isCorrect) {
      borderColor = const Color(0xFF4CAF50);
      bgColor = const Color(0xFF4CAF50).withValues(alpha: 0.12);
      textColor = const Color(0xFF4CAF50);
      trailingIcon = Icons.check_circle_rounded;
    } else if (isSelected) {
      borderColor = const Color(0xFFFF6B6B);
      bgColor = const Color(0xFFFF6B6B).withValues(alpha: 0.12);
      textColor = const Color(0xFFFF6B6B);
      trailingIcon = Icons.cancel_rounded;
    } else {
      borderColor = isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.07);
      bgColor = isDark
          ? Colors.white.withValues(alpha: 0.02)
          : Colors.white.withValues(alpha: 0.60);
      textColor = isDark
          ? Colors.white.withValues(alpha: 0.35)
          : Colors.black.withValues(alpha: 0.35);
      trailingIcon = null;
    }

    return GestureDetector(
      onTap: answered ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                option.palabra,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
            if (trailingIcon != null) ...[
              const SizedBox(width: 8),
              Icon(trailingIcon, size: 20, color: textColor),
            ],
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms, delay: animDelay.ms)
        .slideX(begin: 0.05, end: 0);
  }
}

/// Banner de feedback tras responder.
class _FeedbackBanner extends StatelessWidget {
  final bool isCorrect;
  final String correctWord;
  final bool isDark;

  const _FeedbackBanner({
    required this.isCorrect,
    required this.correctWord,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final color = isCorrect ? const Color(0xFF4CAF50) : const Color(0xFFFF6B6B);
    final icon = isCorrect ? Icons.check_circle_rounded : Icons.info_rounded;
    final text = isCorrect
        ? '¡Correcto! Bien hecho.'
        : 'Incorrecto. Era: $correctWord';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1));
  }
}
