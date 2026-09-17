import 'package:shared_preferences/shared_preferences.dart';
import '../data/signs_database.dart';
import '../models/sign_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ErrorBagService — Singleton
// ─────────────────────────────────────────────────────────────────────────────

/// Servicio que mantiene la "Bolsa de Errores": señas falladas en cualquier
/// quiz. Persiste entre sesiones usando SharedPreferences.
class ErrorBagService {
  ErrorBagService._();
  static final ErrorBagService instance = ErrorBagService._();

  static const String _prefsKey = 'error_bag_ids';

  /// IDs de señas pendientes de refuerzo.
  final Set<String> _pendingIds = {};

  /// Listeners a notificar cuando cambia la bolsa.
  final List<void Function()> _listeners = [];

  // ── Init ──────────────────────────────────────────────────────────────────

  /// Debe llamarse en main() antes de runApp().
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_prefsKey) ?? [];
    _pendingIds.addAll(saved);
  }

  // ── Acceso ────────────────────────────────────────────────────────────────

  /// Cantidad de señas pendientes.
  int get count => _pendingIds.length;

  bool get isEmpty => _pendingIds.isEmpty;

  bool get isNotEmpty => _pendingIds.isNotEmpty;

  /// Lista de SignModel correspondientes a los IDs pendientes.
  List<SignModel> get pendingSigns {
    return signsDatabase
        .where((s) => _pendingIds.contains(s.id))
        .toList();
  }

  // ── Mutaciones ────────────────────────────────────────────────────────────

  /// Agrega una seña fallada.
  Future<void> addError(String signId) async {
    if (_pendingIds.add(signId)) {
      await _persist();
      _notify();
    }
  }

  /// Elimina las señas que el usuario ya respondió correctamente en el repaso.
  Future<void> removeResolved(Set<String> resolvedIds) async {
    _pendingIds.removeAll(resolvedIds);
    await _persist();
    _notify();
  }

  /// Borra toda la bolsa.
  Future<void> clearAll() async {
    _pendingIds.clear();
    await _persist();
    _notify();
  }

  // ── Listeners ─────────────────────────────────────────────────────────────

  void addListener(void Function() listener) => _listeners.add(listener);
  void removeListener(void Function() listener) => _listeners.remove(listener);

  void _notify() {
    for (final l in _listeners) {
      l();
    }
  }

  // ── Persistencia ──────────────────────────────────────────────────────────

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _pendingIds.toList());
  }
}
