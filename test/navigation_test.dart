import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex/screens/pokedex_screen.dart';

void main() {
  testWidgets('abre detalhes, captura e mantém a grade com contador atualizado', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PokedexScreen(useMock: true)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pikachu'));
    await tester.pumpAndSettle();
    expect(find.text('Capturar!'), findsOneWidget);
    expect(find.text('Status base'), findsOneWidget);
    await tester.tap(find.text('Capturar!'));
    await tester.pumpAndSettle();
    expect(find.text('Pikachu foi capturado!'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    await tester.tap(find.text('Pikachu'));
    await tester.pumpAndSettle();
    expect(find.text('Já capturado'), findsOneWidget);
  });

  testWidgets('busca local apresenta mensagem quando não há resultados', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PokedexScreen(useMock: true)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'inexistente');
    await tester.pump();
    expect(find.text('Nenhum Pokémon encontrado.'), findsOneWidget);
  });
}
