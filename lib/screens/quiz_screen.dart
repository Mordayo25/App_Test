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

const int _kQuizCount = 10;
const int _kOptionsCount = 3;

enum _QuizPhaseState { setup, quiz, results }

// ─────────────────────────────────────────────────────────────────────────────
// QuizScreen
// ─────────────────────────────────────────────────────────────────────────────

/// Quiz rápido: selección de categorías → quiz directo → resultados.
/// Sin fase de estudio: el usuario no ve las respuestas antes de intentarlo.
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  // ── Estado ───────────────────────────────────────────────────────────────────
  _QuizPhaseState _phase = _QuizPhaseState.setup;
  late List<SignModel> _quizSet;
  int _currentIndex = 0;
  int _score = 0;

  Set<String> _selectedCategories = {};
  late final List<String> _allCategories;

  List<SignModel>? _currentOptions;
  SignModel? _selectedOption;
  bool _answered = false;

  @override
  void initState() {
    super.initState();
    final seen = <String>{};
    _allCategories = signsDatabase
        .map((s) => s.categoria)
        .where(seen.add)
        .toList()
      ..sort();
    _quizSet = [];
  }

  // ── Lógica ───────────────────────────────────────────────────────────────────

  void _goToSetup() => setState(() => _phase = _QuizPhaseState.setup);

  void _startQuiz() {
    final rng = Random();
    final pool = _selectedCategories.isEmpty
        ? signsDatabase
        : signsDatabase
            .where((s) => _selectedCategories.contains(s.categoria))
            .toList();
    final shuffled = List<SignModel>.from(pool)..shuffle(rng);
    setState(() {
      _quizSet = shuffled.take(_kQuizCount).toList();
      _phase = _QuizPhaseState.quiz;
      _currentIndex = 0;
      _score = 0;
      _selectedOption = null;
      _answered = false;
      _currentOptions = _buildOptions(_quizSet[0]);
    });
  }

  List<SignModel> _buildOptions(SignModel correct) {
    final rng = Random();
    const needed = _kOptionsCount - 1;

    final sameCategory = signsDatabase
        .where((s) => s.id != correct.id && s.categoria == correct.categoria)
        .toList()
      ..shuffle(rng);

    final List<SignModel> picked = sameCategory.take(needed).toList();

    if (picked.length < needed) {
      final usedIds = {correct.id, ...picked.map((s) => s.id)};
      final fallback = signsDatabase
          .where((s) => !usedIds.contains(s.id))
          .toList()
        ..shuffle(rng);
      picked.addAll(fallback.take(needed - picked.length));
    }

    return [correct, ...picked]..shuffle(rng);
  }

  void _selectOption(SignModel option) {
    if (_answered) return;
    final correct = _quizSet[_currentIndex];
    final isCorrect = option.id == correct.id;
    setState(() {
      _selectedOption = option;
      _answered = true;
      if (isCorrect) {
        _score++;
      } else {
        // Registrar error en la bolsa de refuerzo
        ErrorBagService.instance.addError(correct.id);
      }
    });
  }

  void _nextCard() {
    if (_currentIndex < _quizSet.length - 1) {
      final next = _currentIndex + 1;
      setState(() {
        _currentIndex = next;
        _selectedOption = null;
        _answered = false;
        _currentOptions = _buildOptions(_quizSet[next]);
      });
    } else {
      setState(() => _phase = _QuizPhaseState.results);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F0F1E) : const Color(0xFFEEF0FF),
      appBar: _buildAppBar(isDark),
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
            _QuizPhaseState.setup => _QSetupPhase(
                key: const ValueKey('qsetup'),
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
                onStart: _startQuiz,
              ),
            _QuizPhaseState.quiz => _QQuizPhase(
                key: ValueKey('quiz-$_currentIndex-$_answered'),
                sign: _quizSet[_currentIndex],
                options: _currentOptions ?? [],
                index: _currentIndex,
                total: _quizSet.length,
                score: _score,
                selectedOption: _selectedOption,
                answered: _answered,
                isDark: isDark,
                onSelect: _selectOption,
                onNext: _nextCard,
              ),
            _QuizPhaseState.results => _QResultsPhase(
                key: const ValueKey('qresults'),
                score: _score,
                total: _quizSet.length,
                isDark: isDark,
                onRepeat: _goToSetup,
                onHome: () => Navigator.pop(context),
              ),
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    final label = switch (_phase) {
      _QuizPhaseState.setup => 'Configurar',
      _QuizPhaseState.quiz => 'Quiz',
      _QuizPhaseState.results => 'Resultados',
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
          const Icon(Icons.bolt_rounded, color: Color(0xFFFFBF69), size: 20),
          const SizedBox(width: 8),
          Text(
            'Quiz Rápido · $label',
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
// Fase Setup
// ─────────────────────────────────────────────────────────────────────────────

class _QSetupPhase extends StatelessWidget {
  final List<String> allCategories;
  final Set<String> selectedCategories;
  final bool isDark;
  final ValueChanged<String> onToggleCategory;
  final VoidCallback onClearAll;
  final VoidCallback onStart;

  const _QSetupPhase({
    super.key,
    required this.allCategories,
    required this.selectedCategories,
    required this.isDark,
    required this.onToggleCategory,
    required this.onClearAll,
    required this.onStart,
  });

  bool get _isAll => selectedCategories.isEmpty;

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
              // ── Cabecera ──────────────────────────────────────────────────────
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFBF69), Color(0xFFFF6B6B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFBF69).withValues(alpha: 0.40),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.bolt_rounded,
                          color: Colors.white, size: 34),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '¿Sobre qué quieres que te pregunte?',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'En el Quiz Rápido no verás las señas de antemano.\nDebes reconocerlas directamente.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        height: 1.55,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.50)
                            : Colors.black.withValues(alpha: 0.48),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 350.ms).slideY(begin: -0.08, end: 0),

              const SizedBox(height: 28),

              // ── Aviso diferenciador ───────────────────────────────────────────
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFBF69).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFFBF69).withValues(alpha: 0.40),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: Color(0xFFFFBF69), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Sin pistas previas — pon a prueba tu memoria real',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFFFBF69),
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 350.ms, delay: 50.ms),

              const SizedBox(height: 20),

              // ── Tarjeta: Todas ────────────────────────────────────────────────
              _QModeCard(
                icon: Icons.shuffle_rounded,
                title: 'Aleatorio · Todas las señas',
                subtitle: '${signsDatabase.length} señas de todas las categorías',
                isSelected: _isAll,
                accentColor: const Color(0xFFFFBF69),
                isDark: isDark,
                onTap: onClearAll,
              ).animate().fadeIn(duration: 350.ms, delay: 80.ms),

              const SizedBox(height: 20),

              // ── Divisor ───────────────────────────────────────────────────────
              Row(
                children: [
                  Text(
                    'O elige categorías específicas',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.38)
                          : Colors.black.withValues(alpha: 0.38),
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
              ).animate().fadeIn(duration: 350.ms, delay: 110.ms),

              const SizedBox(height: 12),

              // ── Chips ─────────────────────────────────────────────────────────
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: allCategories.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final cat = entry.value;
                  final isSelected =
                      !_isAll && selectedCategories.contains(cat);
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
                            delay: Duration(milliseconds: 130 + idx * 30))
                        .scale(
                            begin: const Offset(0.90, 0.90),
                            end: const Offset(1, 1)),
                  );
                }).toList(),
              ),

              const SizedBox(height: 32),

              // ── Botón Comenzar ────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onStart,
                  icon: const Icon(Icons.bolt_rounded, size: 22),
                  label: Text(
                    _isAll
                        ? '¡Comenzar Quiz! (todas las señas)'
                        : selectedCategories.length == 1
                            ? '¡Comenzar Quiz! · ${selectedCategories.first}'
                            : '¡Comenzar Quiz! · ${selectedCategories.length} categorías',
                    style: GoogleFonts.inter(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B6B),
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
                  .fadeIn(duration: 350.ms, delay: 220.ms)
                  .slideY(begin: 0.1, end: 0),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _QModeCard
// ─────────────────────────────────────────────────────────────────────────────

class _QModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final Color accentColor;
  final bool isDark;
  final VoidCallback onTap;

  const _QModeCard({
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
                color: accentColor.withValues(alpha: isSelected ? 0.22 : 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon,
                  color:
                      accentColor.withValues(alpha: isSelected ? 1.0 : 0.65),
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
              Icon(Icons.check_circle_rounded, color: accentColor, size: 22)
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
// Fase Quiz
// ─────────────────────────────────────────────────────────────────────────────

class _QQuizPhase extends StatelessWidget {
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

  const _QQuizPhase({
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
              // ── Progreso ────────────────────────────────────────────────────
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Quiz · ${index + 1} de $total',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.50)
                              : Colors.black.withValues(alpha: 0.50),
                        ),
                      ),
                      Text(
                        '$score / $total',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFFF6B6B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (index + 1) / total,
                      minHeight: 6,
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.10)
                          : Colors.black.withValues(alpha: 0.08),
                      valueColor: const AlwaysStoppedAnimation(Color(0xFFFF6B6B)),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // ── Categoría badge ─────────────────────────────────────────────
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(iconoParaCategoria(sign.categoria),
                        size: 12, color: color),
                    const SizedBox(width: 5),
                    Text(
                      sign.categoria,
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: color),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              Text(
                '¿Cuál es esta seña?',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),

              const SizedBox(height: 18),

              // ── Imagen ──────────────────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1A1A2E)
                      : Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: color.withValues(alpha: 0.20), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.15),
                      blurRadius: 30,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: _QSignImage(sign: sign, color: color, isDark: isDark),
              )
                  .animate()
                  .fadeIn(duration: 300.ms)
                  .scale(
                      begin: const Offset(0.94, 0.94),
                      end: const Offset(1, 1)),

              const SizedBox(height: 22),

              // ── Opciones ────────────────────────────────────────────────────
              ...List.generate(options.length, (i) {
                final opt = options[i];
                final isCorrect = opt.id == sign.id;
                final isSelected = selectedOption?.id == opt.id;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _QOptionButton(
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

              // ── Feedback ────────────────────────────────────────────────────
              if (answered) ...[
                const SizedBox(height: 8),
                _QFeedbackBanner(
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
                      isLast
                          ? Icons.emoji_events_rounded
                          : Icons.arrow_forward_rounded,
                      size: 18,
                    ),
                    label: Text(
                      isLast ? 'Ver resultados' : 'Siguiente',
                      style: GoogleFonts.inter(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLast
                          ? const Color(0xFFFFBF69)
                          : const Color(0xFFFF6B6B),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
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
// Fase Resultados
// ─────────────────────────────────────────────────────────────────────────────

class _QResultsPhase extends StatelessWidget {
  final int score;
  final int total;
  final bool isDark;
  final VoidCallback onRepeat;
  final VoidCallback onHome;

  const _QResultsPhase({
    super.key,
    required this.score,
    required this.total,
    required this.isDark,
    required this.onRepeat,
    required this.onHome,
  });

  String get _emoji {
    final p = score / total;
    if (p == 1.0) return '🏆';
    if (p >= 0.8) return '🎉';
    if (p >= 0.6) return '👍';
    if (p >= 0.4) return '💪';
    return '📚';
  }

  String get _message {
    final p = score / total;
    if (p == 1.0) return '¡Perfecto! Dominas estas señas.';
    if (p >= 0.8) return '¡Excelente! Casi lo logras.';
    if (p >= 0.6) return '¡Buen esfuerzo! Sigue practicando.';
    if (p >= 0.4) return 'Vas progresando. ¡No te rindas!';
    return 'Repasa el vocabulario y vuelve a intentarlo.';
  }

  Color get _scoreColor {
    final p = score / total;
    if (p >= 0.8) return const Color(0xFF4CAF50);
    if (p >= 0.5) return const Color(0xFFFFBF69);
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
              Text(_emoji, style: const TextStyle(fontSize: 80))
                  .animate()
                  .scale(
                      begin: const Offset(0.3, 0.3),
                      end: const Offset(1, 1),
                      curve: Curves.elasticOut,
                      duration: 800.ms)
                  .fadeIn(duration: 400.ms),

              const SizedBox(height: 24),

              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 28),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1A1A2E)
                      : Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                      color: _scoreColor.withValues(alpha: 0.30), width: 2),
                  boxShadow: [
                    BoxShadow(
                        color: _scoreColor.withValues(alpha: 0.20),
                        blurRadius: 40,
                        offset: const Offset(0, 10)),
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
                              height: 1),
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

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onRepeat,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text('Repetir Quiz',
                      style: GoogleFonts.inter(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B6B),
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
                  label: Text('Volver al Inicio',
                      style: GoogleFonts.inter(
                          fontSize: 15, fontWeight: FontWeight.w600)),
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
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _QSignImage extends StatelessWidget {
  final SignModel sign;
  final Color color;
  final bool isDark;

  const _QSignImage(
      {required this.sign, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.asset(
        sign.pathImagen,
        height: 220,
        width: double.infinity,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => SizedBox(
          height: 220,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.image_not_supported_rounded,
                    size: 48, color: color.withValues(alpha: 0.40)),
                const SizedBox(height: 8),
                Text('Imagen no disponible',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.35)
                            : Colors.black.withValues(alpha: 0.35))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QOptionButton extends StatelessWidget {
  final SignModel option;
  final bool isCorrect;
  final bool isSelected;
  final bool answered;
  final bool isDark;
  final VoidCallback onTap;
  final int animDelay;

  const _QOptionButton({
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
    Color bg;
    Color border;
    Color textColor;
    Widget? trailingIcon;

    if (!answered) {
      bg = isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.white.withValues(alpha: 0.85);
      border = isDark
          ? Colors.white.withValues(alpha: 0.12)
          : Colors.black.withValues(alpha: 0.10);
      textColor = isDark
          ? Colors.white.withValues(alpha: 0.85)
          : const Color(0xFF1A1A2E);
      trailingIcon = null;
    } else if (isCorrect) {
      bg = const Color(0xFF4CAF50).withValues(alpha: 0.15);
      border = const Color(0xFF4CAF50).withValues(alpha: 0.70);
      textColor = const Color(0xFF4CAF50);
      trailingIcon = const Icon(Icons.check_circle_rounded,
          color: Color(0xFF4CAF50), size: 20);
    } else if (isSelected) {
      bg = const Color(0xFFFF6B6B).withValues(alpha: 0.15);
      border = const Color(0xFFFF6B6B).withValues(alpha: 0.70);
      textColor = const Color(0xFFFF6B6B);
      trailingIcon =
          const Icon(Icons.cancel_rounded, color: Color(0xFFFF6B6B), size: 20);
    } else {
      bg = isDark
          ? Colors.white.withValues(alpha: 0.03)
          : Colors.white.withValues(alpha: 0.60);
      border = isDark
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.black.withValues(alpha: 0.06);
      textColor = isDark
          ? Colors.white.withValues(alpha: 0.35)
          : Colors.black.withValues(alpha: 0.35);
      trailingIcon = null;
    }

    return GestureDetector(
      onTap: answered ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border, width: 1.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                option.palabra,
                style: GoogleFonts.inter(
                    fontSize: 15, fontWeight: FontWeight.w600, color: textColor),
              ),
            ),
            if (trailingIcon != null) trailingIcon,
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms, delay: Duration(milliseconds: animDelay))
        .slideX(begin: 0.05, end: 0);
  }
}

class _QFeedbackBanner extends StatelessWidget {
  final bool isCorrect;
  final String correctWord;
  final bool isDark;

  const _QFeedbackBanner({
    required this.isCorrect,
    required this.correctWord,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        isCorrect ? const Color(0xFF4CAF50) : const Color(0xFFFF6B6B);
    final icon = isCorrect
        ? Icons.check_circle_outline_rounded
        : Icons.highlight_off_rounded;
    final text = isCorrect
        ? '¡Correcto! 🎉'
        : 'Incorrecto — la respuesta era: $correctWord';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.40)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w600, color: color),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }
}
