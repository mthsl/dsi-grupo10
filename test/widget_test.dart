import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/main.dart';

void main() {
  testWidgets('exibe a identidade visual e o formulário de login',
      (WidgetTester tester) async {
    await tester.pumpWidget(const AdotaiApp());

    expect(find.text('Adotaí'), findsOneWidget);
    expect(find.text('E-mail'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);
    expect(find.text('Esqueci minha senha'), findsOneWidget);
  });

  testWidgets('permite acessar cadastro com campo endereço',
      (WidgetTester tester) async {
    await tester.pumpWidget(const AdotaiApp());
    await tester.tap(find.text('Criar uma conta'));
    await tester.pumpAndSettle();

    expect(find.text('Criar conta'), findsOneWidget);
    expect(find.text('Endereço'), findsOneWidget);
  });

  testWidgets('valida e confirma recuperação por e-mail',
      (WidgetTester tester) async {
    await tester.pumpWidget(const AdotaiApp());
    await tester.tap(find.text('Esqueci minha senha'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'pessoa@exemplo.com');
    await tester.tap(find.text('Enviar link de recuperação'));
    await tester.pump();

    expect(find.text('Confira seu e-mail'), findsOneWidget);
    expect(find.textContaining('pessoa@exemplo.com'), findsOneWidget);
  });
}
