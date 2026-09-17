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

const int _kOptions = 3;

enum _ReviewPhase { list, quiz, results }

// ─────────────────────────────────────────────────────────────────────────────
// ErrorReviewScreen
// ─────────────────────────────────────────────────────────────────────────────

/// Pantalla de "Bolsa de Errores": muestra las señas pendientes de refuerzo
/// y permite lanzar un quiz con ellas. Las que se respondan correctamente
/// se eliminan de la bolsa.
class ErrorReviewScreen extends StatefulWidget {
  const ErrorReviewScreen({super.key});

  @override
  State<ErrorReviewScreen> createState() => _ErrorReviewScreenState();
}

class _ErrorReviewScreenState extends State<ErrorReviewScreen> {
  final _bag = ErrorBagService.instance;

  _ReviewPhase _phase = _ReviewPhase.list;

  // Quiz state
  late List<SignModel> _quizSet;
  int _currentIndex = 0;
  int _score = 0;
  List<SignModel>? _currentOptions;
  SignModel? _selectedOption;
  bool _answered = false;

  /// IDs respondidos correctamente en este repaso.
  final Set<String> _resolvedThisRound = {};

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

  // ── Quiz lógica ───────────────────────────────────────────────────────────

  void _startQuiz() {
    final rng = Random();
    final pool = List<SignModel>.from(_bag.pendingSigns)..shuffle(rng);
    setState(() {
      _quizSet = pool;
      _phase = _ReviewPhase.quiz;
      _currentIndex = 0;
      _score = 0;
      _selectedOption = null;
      _answered = false;
      _resolvedThisRound.clear();
      _currentOptions = _buildOptions(_quizSet[0]);
    });
  }

  List<SignModel> _buildOptions(SignModel correct) {
    final rng = Random();
    const needed = _kOptions - 1;

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
        _resolvedThisRound.add(correct.id);
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
      _finishQuiz();
    }
  }

  Future<void> _finishQuiz() async {
    // Eliminar de la bolsa solo las que se respondieron bien
    await _bag.removeResolved(_resolvedThisRound);
    setState(() => _phase = _ReviewPhase.results);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

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
            _ReviewPhase.list => _ListPhase(
                key: const ValueKey('list'),
                pendingSigns: _bag.pendingSigns,
                isDark: isDark,
                onStart: _startQuiz,
                onClearAll: () async {
                  await _bag.clearAll();
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            _ReviewPhase.quiz => _ReviewQuizPhase(
                key: ValueKey('rquiz-$_currentIndex-$_answered'),
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
            _ReviewPhase.results => _ReviewResultsPhase(
                key: const ValueKey('rresults'),
                score: _score,
                total: _quizSet.length,
                resolvedCount: _resolvedThisRound.length,
                remainingCount: _bag.count,
                isDark: isDark,
                onRepeat: _bag.isNotEmpty ? _startQuiz : null,
                onHome: () => Navigator.pop(context),
              ),
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    final label = switch (_phase) {
      _ReviewPhase.list => 'Repaso de errores',
      _ReviewPhase.quiz =>
        'Quiz de Repaso · ${_currentIndex + 1}/${_quizSet.length}',
      _ReviewPhase.results => 'Resultados',
    };
    return AppBar(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(Icons.arrow_back_rounded,
            color: isDark
                ? Colors.white.withValues(alpha: 0.80)
                : const Color(0xFF1A1A2E)),
        tooltip: 'Volver',
      ),
      title: Row(
        children: [
          const Icon(Icons.recycling_rounded,
              color: Color(0xFF4CAF50), size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
              overflow: TextOverflow.ellipsis,
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
// Fase Lista
// ─────────────────────────────────────────────────────────────────────────────

class _ListPhase extends StatelessWidget {
  final List<SignModel> pendingSigns;
  final bool isDark;
  final VoidCallback onStart;
  final VoidCallback onClearAll;

  const _ListPhase({
    super.key,
    required this.pendingSigns,
    required this.isDark,
    required this.onStart,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    final count = pendingSigns.length;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          children: [
            // ── Cabecera ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                children: [
                  // Icono + conteo
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4CAF50), Color(0xFF00BCD4)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4CAF50).withValues(alpha: 0.30),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.recycling_rounded,
                            color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bolsa de Errores',
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1A1A2E),
                              ),
                            ),
                            Text(
                              '$count ${count == 1 ? 'seña pendiente' : 'señas pendientes'} de refuerzo',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.50)
                                    : Colors.black.withValues(alpha: 0.48),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 350.ms).slideY(begin: -0.06, end: 0),

                  const SizedBox(height: 16),

                  // Info box
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFF4CAF50).withValues(alpha: 0.30)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            color: Color(0xFF4CAF50), size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Las señas que respondas correctamente desaparecerán de esta lista.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF4CAF50),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 350.ms, delay: 60.ms),

                  const SizedBox(height: 16),

                  // Botones
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onStart,
                          icon: const Icon(Icons.play_arrow_rounded, size: 20),
                          label: Text('Iniciar Quiz de Repaso',
                              style: GoogleFonts.inter(
                                  fontSize: 14, fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: () => _confirmClear(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFFF6B6B),
                          side: BorderSide(
                              color: const Color(0xFFFF6B6B)
                                  .withValues(alpha: 0.50)),
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Icon(Icons.delete_outline_rounded,
                            size: 20),
                      ),
                    ],
                  ).animate().fadeIn(duration: 350.ms, delay: 100.ms),

                  const SizedBox(height: 8),
                ],
              ),
            ),

            // ── Grid de señas ───────────────────────────────────────────────
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                itemCount: pendingSigns.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final sign = pendingSigns[i];
                  final color = colorParaCategoria(sign.categoria);
                  final icon = iconoParaCategoria(sign.categoria);
                  return _PendingSignTile(
                    sign: sign,
                    color: color,
                    icon: icon,
                    isDark: isDark,
                    index: i,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClear(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A1A2E)
            : Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Limpiar bolsa',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text(
          '¿Deseas eliminar todas las señas de la bolsa de errores?',
          style: GoogleFonts.inter(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onClearAll();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B6B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Limpiar',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tile de seña pendiente
// ─────────────────────────────────────────────────────────────────────────────

class _PendingSignTile extends StatelessWidget {
  final SignModel sign;
  final Color color;
  final IconData icon;
  final bool isDark;
  final int index;

  const _PendingSignTile({
    required this.sign,
    required this.color,
    required this.icon,
    required this.isDark,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          // Miniatura
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              sign.pathImagen,
              width: 52,
              height: 52,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Texto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sign.palabra,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(icon, size: 12, color: color),
                    const SizedBox(width: 4),
                    Text(
                      sign.categoria,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B6B).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.close_rounded,
                    size: 12, color: Color(0xFFFF6B6B)),
                const SizedBox(width: 3),
                Text('Pendiente',
                    style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFF6B6B))),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(
            duration: 300.ms,
            delay: Duration(milliseconds: 80 + index * 40))
        .slideX(begin: 0.05, end: 0);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Fase Quiz de Repaso
// ─────────────────────────────────────────────────────────────────────────────

class _ReviewQuizPhase extends StatelessWidget {
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

  const _ReviewQuizPhase({
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
              // Progreso
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Repaso · ${index + 1} de $total',
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
                          color: const Color(0xFF4CAF50),
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
                      valueColor:
                          const AlwaysStoppedAnimation(Color(0xFF4CAF50)),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // Badge categoría
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 5),
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
                    Text(sign.categoria,
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: color)),
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

              // Imagen
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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    sign.pathImagen,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => SizedBox(
                      height: 220,
                      child: Center(
                        child: Icon(Icons.image_not_supported_rounded,
                            size: 48,
                            color: color.withValues(alpha: 0.40)),
                      ),
                    ),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: 300.ms)
                  .scale(
                      begin: const Offset(0.94, 0.94),
                      end: const Offset(1, 1)),

              const SizedBox(height: 22),

              // Opciones
              ...List.generate(options.length, (i) {
                final opt = options[i];
                final isCorrect = opt.id == sign.id;
                final isSelected = selectedOption?.id == opt.id;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ReviewOptionButton(
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
                _ReviewFeedback(
                  isCorrect: selectedOption?.id == sign.id,
                  correctWord: sign.palabra,
                  isDark: isDark,
                  isLast: isLast,
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
                        size: 18),
                    label: Text(isLast ? 'Ver resultados' : 'Siguiente',
                        style: GoogleFonts.inter(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
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

class _ReviewResultsPhase extends StatelessWidget {
  final int score;
  final int total;
  final int resolvedCount;
  final int remainingCount;
  final bool isDark;
  final VoidCallback? onRepeat;
  final VoidCallback onHome;

  const _ReviewResultsPhase({
    super.key,
    required this.score,
    required this.total,
    required this.resolvedCount,
    required this.remainingCount,
    required this.isDark,
    required this.onRepeat,
    required this.onHome,
  });

  Color get _scoreColor {
    final p = score / total;
    if (p >= 0.8) return const Color(0xFF4CAF50);
    if (p >= 0.5) return const Color(0xFFFFBF69);
    return const Color(0xFFFF6B6B);
  }

  @override
  Widget build(BuildContext context) {
    final allCleared = remainingCount == 0;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                allCleared ? '🏆' : score == total ? '🎉' : '💪',
                style: const TextStyle(fontSize: 80),
              )
                  .animate()
                  .scale(
                      begin: const Offset(0.3, 0.3),
                      end: const Offset(1, 1),
                      curve: Curves.elasticOut,
                      duration: 800.ms)
                  .fadeIn(duration: 400.ms),

              const SizedBox(height: 24),

              // Tarjeta puntaje
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 24),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1A1A2E)
                      : Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                      color: _scoreColor.withValues(alpha: 0.30), width: 2),
                  boxShadow: [
                    BoxShadow(
                        color: _scoreColor.withValues(alpha: 0.18),
                        blurRadius: 40,
                        offset: const Offset(0, 10)),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'RESULTADOS DEL REPASO',
                      style: GoogleFonts.inter(
                        fontSize: 11,
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
                        Text('$score',
                            style: GoogleFonts.inter(
                                fontSize: 64,
                                fontWeight: FontWeight.w900,
                                color: _scoreColor,
                                height: 1)),
                        Text(' / $total',
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.38)
                                  : Colors.black.withValues(alpha: 0.38),
                            )),
                      ],
                    ),
                    const SizedBox(height: 14),
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
                    const SizedBox(height: 20),

                    // Stats de la bolsa
                    Row(
                      children: [
                        Expanded(
                          child: _StatBox(
                            label: 'Resueltas',
                            value: '$resolvedCount',
                            color: const Color(0xFF4CAF50),
                            icon: Icons.check_circle_rounded,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatBox(
                            label: 'Aún pendientes',
                            value: '$remainingCount',
                            color: remainingCount == 0
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFFFF6B6B),
                            icon: remainingCount == 0
                                ? Icons.done_all_rounded
                                : Icons.pending_rounded,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),

                    if (allCleared) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: const Color(0xFF4CAF50)
                                  .withValues(alpha: 0.35)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.done_all_rounded,
                                color: Color(0xFF4CAF50), size: 16),
                            const SizedBox(width: 6),
                            Text(
                              '¡Bolsa vacía! No tienes errores pendientes.',
                              style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF4CAF50)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              )
                  .animate()
                  .fadeIn(duration: 500.ms, delay: 300.ms)
                  .slideY(begin: 0.12, end: 0),

              const SizedBox(height: 28),

              if (onRepeat != null) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onRepeat,
                    icon:
                        const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(
                        'Repasar $remainingCount señas restantes',
                        style: GoogleFonts.inter(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
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
              ],

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

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final bool isDark;

  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: color)),
          Text(label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.45)
                    : Colors.black.withValues(alpha: 0.45),
              )),
        ],
      ),
    );
  }
}

class _ReviewOptionButton extends StatelessWidget {
  final SignModel option;
  final bool isCorrect;
  final bool isSelected;
  final bool answered;
  final bool isDark;
  final VoidCallback onTap;
  final int animDelay;

  const _ReviewOptionButton({
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
    Widget? trailing;

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
      trailing = null;
    } else if (isCorrect) {
      bg = const Color(0xFF4CAF50).withValues(alpha: 0.15);
      border = const Color(0xFF4CAF50).withValues(alpha: 0.70);
      textColor = const Color(0xFF4CAF50);
      trailing = const Icon(Icons.check_circle_rounded,
          color: Color(0xFF4CAF50), size: 20);
    } else if (isSelected) {
      bg = const Color(0xFFFF6B6B).withValues(alpha: 0.15);
      border = const Color(0xFFFF6B6B).withValues(alpha: 0.70);
      textColor = const Color(0xFFFF6B6B);
      trailing = const Icon(Icons.cancel_rounded,
          color: Color(0xFFFF6B6B), size: 20);
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
      trailing = null;
    }

    return GestureDetector(
      onTap: answered ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border, width: 1.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(option.palabra,
                  style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textColor)),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(
            duration: 300.ms,
            delay: Duration(milliseconds: animDelay))
        .slideX(begin: 0.05, end: 0);
  }
}

class _ReviewFeedback extends StatelessWidget {
  final bool isCorrect;
  final String correctWord;
  final bool isDark;
  final bool isLast;

  const _ReviewFeedback({
    required this.isCorrect,
    required this.correctWord,
    required this.isDark,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        isCorrect ? const Color(0xFF4CAF50) : const Color(0xFFFF6B6B);
    final icon = isCorrect
        ? Icons.check_circle_outline_rounded
        : Icons.highlight_off_rounded;
    final text = isCorrect
        ? isLast
            ? '¡Correcto! ✅ Eliminada de tu bolsa de errores.'
            : '¡Correcto! ✅ Se eliminará de tu bolsa.'
        : 'Incorrecto — la respuesta era: $correctWord. Sigue en tu bolsa.';

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
            child: Text(text,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                    height: 1.4)),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }
}
