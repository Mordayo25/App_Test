import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/sign_model.dart';
import '../data/signs_database.dart';

/// Widget que muestra el panel de búsqueda y la lista de señas disponibles.
class SignListPanel extends StatelessWidget {
  /// Texto actual del buscador.
  final String query;

  /// Categoría seleccionada como filtro.
  final String categoriaSeleccionada;

  /// Lista de señas filtradas a mostrar.
  final List<SignModel> senas;

  /// Seña actualmente seleccionada (para resaltarla en la lista).
  final SignModel? senaSeleccionada;

  /// Lista de categorías disponibles para el filtro.
  final List<String> categorias;

  /// Controlador del TextField de búsqueda.
  final TextEditingController searchController;

  /// Callback al cambiar el texto de búsqueda.
  final ValueChanged<String> onSearchChanged;

  /// Callback al seleccionar una categoría.
  final ValueChanged<String> onCategoriaChanged;

  /// Callback al seleccionar una seña.
  final ValueChanged<SignModel> onSenaSelected;

  const SignListPanel({
    super.key,
    required this.query,
    required this.categoriaSeleccionada,
    required this.senas,
    required this.senaSeleccionada,
    required this.categorias,
    required this.searchController,
    required this.onSearchChanged,
    required this.onCategoriaChanged,
    required this.onSenaSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF8F9FF),
        border: Border(
          right: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.10) : Colors.black.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────────────────
          _PanelHeader(isDark: isDark),

          // ── Buscador ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: _SearchField(
              controller: searchController,
              onChanged: onSearchChanged,
              isDark: isDark,
            ),
          ),

          // ── Filtro por categoría (Dropdown) ────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: _CategoryDropdown(
              categorias: categorias,
              categoriaSeleccionada: categoriaSeleccionada,
              onCategoriaChanged: onCategoriaChanged,
              isDark: isDark,
            ),
          ),

          const SizedBox(height: 12),

          // ── Contador ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '${senas.length} señas encontradas',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark ? Colors.white.withValues(alpha: 0.38) : Colors.black.withValues(alpha: 0.38),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // ── Lista de señas ─────────────────────────────────────────────────
          Expanded(
            child: senas.isEmpty
                ? _EmptyListMessage(isDark: isDark)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: senas.length,
                    itemBuilder: (context, index) {
                      final sign = senas[index];
                      final isSelected =
                          senaSeleccionada?.id == sign.id;

                      return _SignListItem(
                        sign: sign,
                        isSelected: isSelected,
                        isDark: isDark,
                        onTap: () => onSenaSelected(sign),
                        animationIndex: index,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Subwidgets internos ────────────────────────────────────────────────────

/// Dropdown estilizado para seleccionar una categoría.
class _CategoryDropdown extends StatelessWidget {
  final List<String> categorias;
  final String categoriaSeleccionada;
  final ValueChanged<String> onCategoriaChanged;
  final bool isDark;

  const _CategoryDropdown({
    required this.categorias,
    required this.categoriaSeleccionada,
    required this.onCategoriaChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final selectedColor = categoriaSeleccionada == 'Todas'
        ? const Color(0xFF6C63FF)
        : colorParaCategoria(categoriaSeleccionada);

    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.07)
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selectedColor.withValues(alpha: 0.45),
          width: 1.5,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: DropdownButtonHideUnderline(
        child: ButtonTheme(
          alignedDropdown: true,
          child: DropdownButton<String>(
            value: categoriaSeleccionada,
            isExpanded: true,
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: selectedColor,
              size: 20,
            ),
            dropdownColor: isDark ? const Color(0xFF1E1E35) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            ),
            selectedItemBuilder: (context) {
              return categorias.map((cat) {
                final color = cat == 'Todas'
                    ? const Color(0xFF6C63FF)
                    : colorParaCategoria(cat);
                final icon = cat == 'Todas'
                    ? Icons.grid_view_rounded
                    : iconoParaCategoria(cat);
                return Row(
                  children: [
                    const SizedBox(width: 4),
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Icon(icon, size: 14, color: color),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      cat,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
            items: categorias.map((cat) {
              final isSelected = cat == categoriaSeleccionada;
              final color = cat == 'Todas'
                  ? const Color(0xFF6C63FF)
                  : colorParaCategoria(cat);
              final icon = cat == 'Todas'
                  ? Icons.grid_view_rounded
                  : iconoParaCategoria(cat);

              return DropdownMenuItem<String>(
                value: cat,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: isSelected
                      ? BoxDecoration(
                          color: color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        )
                      : null,
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: isSelected ? 0.20 : 0.10),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, size: 15, color: color),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        cat,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? color
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.87)
                                  : const Color(0xFF1A1A2E)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) onCategoriaChanged(value);
            },
          ),
        ),
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  final bool isDark;
  const _PanelHeader({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF48CAE4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.sign_language,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'LSP',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Lengua de Señas Peruana',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isDark ? Colors.white.withValues(alpha: 0.38) : Colors.black.withValues(alpha: 0.38),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool isDark;

  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.07)
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: GoogleFonts.inter(
          fontSize: 14,
          color: isDark ? Colors.white : const Color(0xFF1A1A2E),
        ),
        decoration: InputDecoration(
          hintText: 'Buscar seña... (ej. "Hola")',
          hintStyle: GoogleFonts.inter(
            fontSize: 14,
            color: isDark ? Colors.white.withValues(alpha: 0.30) : Colors.black.withValues(alpha: 0.30),
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: isDark ? Colors.white.withValues(alpha: 0.38) : const Color(0xFF6C63FF),
            size: 20,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: isDark ? Colors.white.withValues(alpha: 0.38) : Colors.black.withValues(alpha: 0.38),
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}

class _SignListItem extends StatelessWidget {
  final SignModel sign;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;
  final int animationIndex;

  const _SignListItem({
    required this.sign,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
    required this.animationIndex,
  });

  @override
  Widget build(BuildContext context) {
    final color = colorParaCategoria(sign.categoria);
    final icono = iconoParaCategoria(sign.categoria);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: isDark ? 0.25 : 0.12)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? color.withValues(alpha: 0.6)
                  : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : (isDark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )
                      ]),
          ),
          child: Row(
            children: [
              // Ícono de categoría
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isSelected ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icono, size: 18, color: color),
              ),
              const SizedBox(width: 12),

              // Nombre y categoría
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sign.palabra,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected
                            ? color
                            : (isDark ? Colors.white.withValues(alpha: 0.87) : const Color(0xFF1A1A2E)),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sign.categoria,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isDark ? Colors.white.withValues(alpha: 0.38) : Colors.black.withValues(alpha: 0.38),
                      ),
                    ),
                  ],
                ),
              ),

              // Flecha
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: isSelected ? color : Colors.black26,
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(
              duration: 250.ms,
              delay: (animationIndex * 30).ms,
            )
            .slideX(begin: -0.05, end: 0),
      ),
    );
  }
}

class _EmptyListMessage extends StatelessWidget {
  final bool isDark;
  const _EmptyListMessage({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 48,
            color: isDark ? Colors.white.withValues(alpha: 0.24) : Colors.black.withValues(alpha: 0.24),
          ),
          const SizedBox(height: 12),
          Text(
            'Sin resultados',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white.withValues(alpha: 0.38) : Colors.black.withValues(alpha: 0.38),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Intenta con otro término\no cambia la categoría',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isDark ? Colors.white.withValues(alpha: 0.24) : Colors.black.withValues(alpha: 0.24),
            ),
          ),
        ],
      ),
    );
  }
}
