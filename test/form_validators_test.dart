import 'package:flutter_test/flutter_test.dart';
import 'package:reportes_ciudadanos/core/validators/form_validators.dart';

void main() {
  group('Pruebas de validación de formularios', () {

    test('1. Rechaza un correo electrónico vacío', () {
      // Arrange
      const email = '';

      // Act
      final resultado = FormValidators.validateEmail(email);

      // Assert
      expect(resultado, 'Ingresa tu correo electrónico');
    });

    test('2. Rechaza un correo electrónico con formato incorrecto', () {
      // Arrange
      const email = 'usuario-sin-formato';

      // Act
      final resultado = FormValidators.validateEmail(email);

      // Assert
      expect(resultado, 'Ingresa un correo válido');
    });

    test('3. Acepta un correo electrónico válido', () {
      // Arrange
      const email = 'usuario@gmail.com';

      // Act
      final resultado = FormValidators.validateEmail(email);

      // Assert
      expect(resultado, isNull);
    });

    test('4. Rechaza una contraseña vacía', () {
      // Arrange
      const password = '';

      // Act
      final resultado = FormValidators.validatePassword(
        password,
        register: true,
      );

      // Assert
      expect(resultado, 'Ingresa tu contraseña');
    });

    test('5. Rechaza una contraseña corta durante el registro', () {
      // Arrange
      const password = 'abc123';

      // Act
      final resultado = FormValidators.validatePassword(
        password,
        register: true,
      );

      // Assert
      expect(resultado, 'Usa al menos 8 caracteres');
    });

    test('6. Acepta una contraseña de al menos ocho caracteres', () {
      // Arrange
      const password = 'clave123';

      // Act
      final resultado = FormValidators.validatePassword(
        password,
        register: true,
      );

      // Assert
      expect(resultado, isNull);
    });

    test('7. Rechaza un título demasiado corto', () {
      // Arrange
      const titulo = 'Luz';

      // Act
      final resultado = FormValidators.validateReportTitle(titulo);

      // Assert
      expect(resultado, 'Escribe un título de al menos 5 caracteres');
    });

    test('8. Acepta un título válido', () {
      // Arrange
      const titulo = 'Poste apagado';

      // Act
      final resultado = FormValidators.validateReportTitle(titulo);

      // Assert
      expect(resultado, isNull);
    });

    test('9. Rechaza una descripción demasiado corta', () {
      // Arrange
      const descripcion = 'Hay basura';

      // Act
      final resultado =
          FormValidators.validateReportDescription(descripcion);

      // Assert
      expect(
        resultado,
        'Describe el problema con al menos 15 caracteres',
      );
    });

    test('10. Acepta una descripción válida', () {
      // Arrange
      const descripcion = 'Existe acumulación de basura en la calle.';

      // Act
      final resultado =
          FormValidators.validateReportDescription(descripcion);

      // Assert
      expect(resultado, isNull);
    });

    test('11. Rechaza un campo obligatorio vacío', () {
      // Arrange
      const nombre = '   ';

      // Act
      final resultado = FormValidators.validateRequired(nombre);

      // Assert
      expect(resultado, 'Este campo es obligatorio');
    });
        test('12. FALLA INTENCIONALMENTE: acepta un correo inválido', () {
      // Arrange
      const email = 'correo-invalido';

      // Act
      final resultado = FormValidators.validateEmail(email);

      // Assert
      expect(resultado, isNull);
    });
  });
}