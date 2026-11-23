# App Ciudadana — Puerto Quijarro

Aplicación Flutter multiplataforma para reportes ciudadanos. Este corte implementa la bienvenida adaptable y los formularios de inicio de sesión/registro conectables a Supabase.

## Requisitos

- Flutter compatible con Dart `^3.13.5` (ver `pubspec.yaml`).
- Proyecto Supabase.
- La clave pública `anon`/`publishable` del proyecto para habilitar autenticación desde el cliente.

## Ejecutar

```bash
flutter pub get
flutter run --dart-define=SUPABASE_ANON_KEY=TU_CLAVE_PUBLICA
```

La URL del proyecto actual está configurada como valor predeterminado. Puede sustituirse con `--dart-define=SUPABASE_URL=https://TU_PROYECTO.supabase.co`.

**Seguridad:** nunca incluyas `service_role` ni secretos de servidor en la aplicación móvil/web. La asignación de roles privilegiados (funcionario/administrador) debe hacerse desde un entorno confiable y protegerse con políticas RLS; el registro público solo solicita el rol ciudadano.

## Estado actual

- [x] Bienvenida y navegación a acceso/registro.
- [x] Validación básica de nombre, correo y contraseña.
- [x] Integración de llamadas Supabase Auth cuando existe configuración.
- [x] Inicio sin bloqueo cuando falta la clave pública; muestra instrucciones de configuración.
- [ ] Perfil y autorización por roles con políticas RLS.
- [ ] Creación de reportes, GPS/mapa, fotos, seguimiento y paneles de gestión.

## Pruebas

```bash
flutter test
```

## Ubicación GPS y mapa (avance 2)

Este avance incorpora captura GPS con permiso del dispositivo/navegador, visualización de precisión estimada en metros, selección/ajuste manual del punto en un mapa OpenStreetMap y guardado de latitud, longitud, precisión y fecha/hora UTC en cada reporte.

Antes de crear reportes con ubicación, ejecuta `supabase/location_migration.sql` en Supabase > SQL Editor. La migración añade columnas sin borrar los reportes existentes.

En Chrome, permite el acceso a la ubicación cuando el navegador lo solicite. En Windows, activa también los servicios de ubicación. Para desarrollo web usa `localhost` o HTTPS; los navegadores restringen geolocalización en páginas no seguras.

Dependencias añadidas: `geolocator`, `flutter_map` y `latlong2`. El mapa usa teselas de OpenStreetMap; requiere conexión a internet.
