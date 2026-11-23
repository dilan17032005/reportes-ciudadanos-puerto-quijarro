import 'package:flutter_test/flutter_test.dart';
import 'package:reportes_ciudadanos/main.dart';

Future<void> tocarElementoVisible(
  WidgetTester tester,
  Finder elemento,
) async {
  await tester.ensureVisible(elemento);
  await tester.pumpAndSettle();
  await tester.tap(elemento);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('La bienvenida muestra acceso y registro', (tester) async {
    await tester.pumpWidget(const ReportesCiudadanosApp());

    expect(find.text('REPORTES CIUDADANOS'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Crear una cuenta'), findsOneWidget);
  });

  testWidgets('El formulario de acceso valida correo y contraseña',
      (tester) async {
    await tester.pumpWidget(const ReportesCiudadanosApp());

    await tocarElementoVisible(
      tester,
      find.text('Iniciar sesión'),
    );

    await tocarElementoVisible(
      tester,
      find.text('Ingresar'),
    );

    expect(find.text('Ingresa tu correo electrónico'), findsOneWidget);
    expect(find.text('Ingresa tu contraseña'), findsOneWidget);
  });

  testWidgets('El registro solicita nombre y contraseña segura',
      (tester) async {
    await tester.pumpWidget(const ReportesCiudadanosApp());

    await tocarElementoVisible(
      tester,
      find.text('Crear una cuenta'),
    );

    expect(find.text('Nombre completo'), findsOneWidget);
    expect(find.text('Crear cuenta'), findsOneWidget);
  });
}