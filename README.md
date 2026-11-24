# Reportes Ciudadanos - Puerto Quijarro

[![Pruebas automatizadas Flutter](https://github.com/dilan17032005/reportes-ciudadanos-puerto-quijarro/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/dilan17032005/reportes-ciudadanos-puerto-quijarro/actions/workflows/ci.yml)

Estado del pipeline de pruebas automatizadas.

Aplicacion desarrollada con Flutter para facilitar el registro y seguimiento de reportes ciudadanos en el municipio de Puerto Quijarro, Bolivia.

El proyecto utiliza Supabase para los servicios de autenticacion y gestion de datos.

## Tecnologias utilizadas

- Flutter 3.49.0-1.0.pre-91
- Dart 3.13.5
- Supabase
- Git y GitHub
- GitHub Actions
- OpenStreetMap
- Geolocator
- Flutter Map
- Latlong2

## Requisitos

- Flutter instalado.
- Dart compatible con la version indicada en pubspec.yaml.
- Un proyecto configurado en Supabase.
- Una clave publica de Supabase para habilitar la autenticacion.

## Instalacion y ejecucion

Clonar el repositorio:

    git clone https://github.com/dilan17032005/reportes-ciudadanos-puerto-quijarro.git

Ingresar a la carpeta:

    cd reportes-ciudadanos-puerto-quijarro

Instalar las dependencias:

    flutter pub get

Configurar las credenciales publicas de Supabase en:

    lib/core/config/supabase_config.dart

Ejecutar la aplicacion:

    flutter run

## Seguridad

- No publicar claves secretas ni credenciales de servidor.
- No incluir claves service_role en la aplicacion.
- Utilizar unicamente la clave publica correspondiente al cliente.
- Proteger las operaciones y los datos mediante politicas RLS en Supabase.
- No asignar roles privilegiados desde el registro publico.

## Funcionalidades del proyecto

- Pantalla de bienvenida.
- Navegacion hacia inicio de sesion y registro.
- Formularios con validaciones.
- Integracion de autenticacion con Supabase.
- Pantallas para ciudadanos y administracion.
- Registro y consulta de reportes ciudadanos.
- Captura de fotografias desde la aplicacion.
- Captura de ubicacion GPS.
- Visualizacion y ajuste de ubicacion mediante OpenStreetMap.

Las funciones que dependen de Supabase requieren una configuracion valida del servicio.

## Pruebas automatizadas

El proyecto cuenta con 14 pruebas automatizadas distribuidas en dos archivos.

### Pruebas de validacion

Archivo: test/form_validators_test.dart

Se realizan 11 pruebas:

1. Rechazo de correo electronico vacio.
2. Rechazo de correo electronico con formato incorrecto.
3. Aceptacion de correo electronico valido.
4. Rechazo de contrasena vacia.
5. Rechazo de contrasena corta durante el registro.
6. Aceptacion de contrasena de al menos ocho caracteres.
7. Rechazo de titulo demasiado corto.
8. Aceptacion de titulo valido.
9. Rechazo de descripcion demasiado corta.
10. Aceptacion de descripcion valida.
11. Rechazo de campo obligatorio vacio.

### Pruebas de interfaz

Archivo: test/widget_test.dart

Se realizan 3 pruebas:

1. Visualizacion de bienvenida y opciones de acceso y registro.
2. Validacion de correo y contrasena en el formulario de acceso.
3. Solicitud de nombre y contrasena segura en el registro.

### Ejecutar las pruebas

Ejecutar todas las pruebas:

    flutter test

Ejecutar solamente las pruebas de validacion:

    flutter test test/form_validators_test.dart

Mostrar los nombres de las pruebas:

    flutter test --reporter expanded

Ultimo resultado verificado: 14 pruebas aprobadas y ninguna fallida.

## Integracion continua (CI/CD)

El repositorio utiliza GitHub Actions para ejecutar automaticamente las pruebas de Flutter.

Archivo de configuracion:

    .github/workflows/ci.yml

El flujo de trabajo realiza las siguientes actividades:

1. Descarga el codigo del repositorio.
2. Configura el entorno Flutter.
3. Instala las dependencias.
4. Ejecuta las pruebas automatizadas mediante flutter test.

El pipeline se ejecuta cuando se realiza un push o pull request dirigido a la rama main.

### Resultados del pipeline

Los resultados se pueden consultar en la pestana Actions:
4.
https://github.com/dilan17032005/reportes-ciudadanos-puerto-quijarro/actions

### Comprobacion de fallos

Durante la practica se agrego temporalmente una prueba con un resultado esperado incorrecto para comprobar que GitHub Actions detectara el error.

El pipeline identifico la prueba fallida y mostro el estado Failure.

Posteriormente se retiro la prueba temporal, se ejecutaron nuevamente las 14 pruebas y se verifico que el pipeline recuperara el estado Success.

## Ubicacion GPS y mapa

El proyecto incorpora funcionalidades de ubicacion mediante GPS y visualizacion en un mapa.

Dependencias utilizadas:

- geolocator
- flutter_map
- latlong2

El mapa utiliza teselas de OpenStreetMap y requiere conexion a internet.

Para utilizar la ubicacion en el navegador se deben conceder los permisos correspondientes. En desarrollo web se recomienda utilizar localhost o HTTPS.

La migracion de base de datos relacionada con la ubicacion se encuentra en:

    supabase/location_migration.sql

## Repositorio

Codigo fuente:

https://github.com/dilan17032005/reportes-ciudadanos-puerto-quijarro

## Autor

Proyecto academico desarrollado para la asignatura Lenguajes de Ultima Generacion.

Universidad Tecnica Privada Cosmos.
Gestion 2026.
