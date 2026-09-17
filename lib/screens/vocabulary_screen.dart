import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/signs_database.dart';
import '../models/sign_model.dart';
import '../widgets/sign_list_panel.dart';
import '../widgets/sign_viewer_panel.dart';

/// Pantalla de exploración de vocabulario LSP.
/// Migrada desde el antiguo HomeScreen — mantiene el diseño adaptativo
/// con panel izquierdo (buscador + lista) y panel derecho (imagen + info).
class VocabularyScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const VocabularyScreen({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen> {
  // ── Estado ──────────────────────────────────────────────────────────────────
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _categoriaSeleccionada = 'Todas';
  SignModel? _senaSeleccionada;

  List<SignModel> get _senasFiltradas => filtrarSenas(
        query: _query,
        categoria: _categoriaSeleccionada,
      );

  // ── Handlers ────────────────────────────────────────────────────────────────
  void _onSearchChanged(String value) => setState(() => _query = value);
  void _onCategoriaChanged(String categoria) =>
      setState(() => _categoriaSeleccionada = categoria);
  void _onSenaSelected(SignModel sign) {
    setState(() => _senaSeleccionada = sign);

    // Si la pantalla es pequeña (móvil), mostramos el visor en un BottomSheet
    final isWide = MediaQuery.of(context).size.width >= 700;
    if (!isWide) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F0F1E) : const Color(0xFFEEF0FF),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Indicador de arrastre (Handle)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Expanded(
                  child: SignViewerPanel(senaSeleccionada: sign),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F0F1E) : const Color(0xFFEEF0FF),
      appBar: _buildAppBar(context, isDark),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 700;

          if (isWide) {
            return Row(
              children: [
                SizedBox(
                  width: constraints.maxWidth * 0.38,
                  child: _buildListPanel(),
                ),
                Expanded(child: _buildViewerPanel()),
              ],
            );
          } else {
            // En móvil, la lista ocupa toda la pantalla.
            // El visor se abre en el BottomSheet (ver _onSenaSelected).
            return _buildListPanel();
          }
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDark) {
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
          const Icon(Icons.menu_book_rounded,
              color: Color(0xFF6C63FF), size: 20),
          const SizedBox(width: 8),
          Text(
            'Vocabulario',
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${signsDatabase.length} señas',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6C63FF),
              ),
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
              widget.isDarkMode
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
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

  Widget _buildListPanel() => SignListPanel(
        query: _query,
        categoriaSeleccionada: _categoriaSeleccionada,
        senas: _senasFiltradas,
        senaSeleccionada: _senaSeleccionada,
        categorias: categorias,
        searchController: _searchController,
        onSearchChanged: _onSearchChanged,
        onCategoriaChanged: _onCategoriaChanged,
        onSenaSelected: _onSenaSelected,
      );

  Widget _buildViewerPanel() =>
      SignViewerPanel(senaSeleccionada: _senaSeleccionada);
}
