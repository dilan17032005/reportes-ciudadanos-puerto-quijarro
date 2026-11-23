class FormValidators {
  static String? validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo es obligatorio';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresa tu correo electrónico';
    }

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
        .hasMatch(value.trim())) {
      return 'Ingresa un correo válido';
    }

    return null;
  }

  static String? validatePassword(
    String? value, {
    bool register = false,
  }) {
    if (value == null || value.isEmpty) {
      return 'Ingresa tu contraseña';
    }

    if (register && value.length < 8) {
      return 'Usa al menos 8 caracteres';
    }

    return null;
  }

  static String? validateReportTitle(String? value) {
    if (value == null || value.trim().length < 5) {
      return 'Escribe un título de al menos 5 caracteres';
    }

    return null;
  }

  static String? validateReportDescription(String? value) {
    if (value == null || value.trim().length < 15) {
      return 'Describe el problema con al menos 15 caracteres';
    }

    return null;
  }
}