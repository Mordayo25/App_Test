# MaxiSeñas LSP 🤝

Aplicación Flutter para el aprendizaje de **Lengua de Señas Peruana (LSP)**.

---

## Estructura del Proyecto

```
sign_language_app/
├── lib/
│   ├── main.dart                    ← Punto de entrada
│   ├── data/
│   │   └── signs_database.dart      ← Base de datos estática (18 señas, 6 categorías)
│   ├── models/
│   │   └── sign_model.dart          ← Modelo de datos SignModel
│   ├── screens/
│   │   └── home_screen.dart         ← Pantalla principal con layout adaptativo
│   └── widgets/
│       ├── sign_list_panel.dart     ← Panel izquierdo: buscador + lista
│       └── sign_viewer_panel.dart   ← Panel derecho: visualizador de seña
├── assets/
│   ├── images/                      ← ⚠️ Aquí van las imágenes de las señas
│   └── placeholder/                 ← Carpeta reservada para otros assets
└── pubspec.yaml
```

---

## Cómo agregar imágenes

Coloca las imágenes **PNG** de cada seña en `assets/images/` con el nombre exacto
que aparece en `signs_database.dart`:

| Palabra       | Archivo requerido                    |
|---------------|--------------------------------------|
| Hola          | `assets/images/hola.png`            |
| Adiós         | `assets/images/adios.png`           |
| Buenos días   | `assets/images/buenos_dias.png`     |
| Gracias       | `assets/images/gracias.png`         |
| Por favor     | `assets/images/por_favor.png`       |
| Perdón        | `assets/images/perdon.png`          |
| Comida        | `assets/images/comida.png`          |
| Agua          | `assets/images/agua.png`            |
| Leche         | `assets/images/leche.png`           |
| Mamá          | `assets/images/mama.png`            |
| Papá          | `assets/images/papa.png`            |
| Hermano       | `assets/images/hermano.png`         |
| Feliz         | `assets/images/feliz.png`           |
| Triste        | `assets/images/triste.png`          |
| Sí            | `assets/images/si.png`              |
| No            | `assets/images/no.png`              |
| Ayuda         | `assets/images/ayuda.png`           |
| Baño          | `assets/images/bano.png`            |

> Si una imagen no existe, la app mostrará un **placeholder elegante** con el
> ícono de la categoría y la ruta del archivo esperado.

---

## Instalación y Ejecución

```bash
# 1. Instalar dependencias
flutter pub get

# 2. Ejecutar en el dispositivo conectado o emulador
flutter run

# 3. Ejecutar en web
flutter run -d chrome

# 4. Compilar para producción
flutter build apk        # Android
flutter build ios        # iOS
flutter build web        # Web
```

---

## Agregar nuevas señas

Edita `lib/data/signs_database.dart` y añade un nuevo `SignModel` a la lista:

```dart
SignModel(
  id: 'X001',                          // ID único
  palabra: 'Casa',                     // Texto de la seña
  categoria: 'General',                // Categoría existente o nueva
  pathImagen: 'assets/images/casa.png',// Ruta del asset
  colorCategoria: 0xFF42A5F5,          // Color hex de la categoría
  iconoCategoria: 0xe876,              // Código del ícono de Material
),
```

Luego coloca la imagen `casa.png` en `assets/images/` y ejecuta `flutter pub get`.

---

## Dependencias

| Paquete           | Versión  | Uso                            |
|-------------------|----------|--------------------------------|
| `google_fonts`    | ^6.2.1   | Tipografía Inter               |
| `flutter_animate` | ^4.5.0   | Micro-animaciones fluidas      |

---

## Características

- 🔍 **Búsqueda en tiempo real** — filtra la lista mientras escribes
- 🏷️ **Filtro por categoría** — chips horizontales con scroll
- 📱 **Layout adaptativo** — móvil (vertical 50/50) y tablet/web (horizontal)
- 🌙 **Tema oscuro/claro** — toggle en el AppBar
- ✨ **Animaciones** — transiciones suaves al cambiar de seña
- 🖼️ **Placeholder inteligente** — muestra ruta requerida si falta la imagen
