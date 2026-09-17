// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:sign_language_app/main.dart';

import 'package:sign_language_app/data/signs_database.dart';

void main() {
  testWidgets('SignLanguageApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SignLanguageApp());
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(SignLanguageApp), findsOneWidget);
  });

  test('filtrarSenas búsqueda sin tildes', () {
    final resultadosComo = filtrarSenas(query: 'como');
    expect(resultadosComo.any((s) => s.palabra == '¿Cómo estás?'), isTrue);

    final resultadosAdios = filtrarSenas(query: 'adios');
    expect(resultadosAdios.any((s) => s.palabra == 'Adiós'), isTrue);

    final resultadosDias = filtrarSenas(query: 'dias');
    expect(resultadosDias.any((s) => s.palabra == 'Buenos días'), isTrue);

    final resultadosMiercoles = filtrarSenas(query: 'miercoles');
    expect(resultadosMiercoles.any((s) => s.palabra == 'Miércoles'), isTrue);

    final resultadosTu = filtrarSenas(query: 'tu');
    expect(resultadosTu.any((s) => s.palabra == 'Tú'), isTrue);

    final resultadosEl = filtrarSenas(query: 'el');
    expect(resultadosEl.any((s) => s.palabra == 'Él'), isTrue);

    final senasPronombres = filtrarSenas(categoria: 'Pronombres');
    expect(senasPronombres.length, equals(8));

    final senasPreguntas = filtrarSenas(categoria: 'Preguntas');
    expect(senasPreguntas.length, equals(10));

    final senasMeses = filtrarSenas(categoria: 'Meses');
    expect(senasMeses.length, equals(12));

    final senasFamiliares = filtrarSenas(categoria: 'Familiares');
    expect(senasFamiliares.length, equals(41));

    final resultadosMama = filtrarSenas(query: 'mama');
    expect(resultadosMama.any((s) => s.palabra == 'Mamá'), isTrue);

    final resultadosTio = filtrarSenas(query: 'tio');
    expect(resultadosTio.any((s) => s.palabra == 'Tío'), isTrue);

    final senasTiempo = filtrarSenas(categoria: 'Tiempo');
    expect(senasTiempo.length, equals(32));

    final resultadosAyer = filtrarSenas(query: 'ayer');
    expect(resultadosAyer.any((s) => s.palabra == 'Ayer'), isTrue);

    final resultadosProximo = filtrarSenas(query: 'proximo');
    expect(resultadosProximo.any((s) => s.palabra == 'Próximo'), isTrue);
  });
}
