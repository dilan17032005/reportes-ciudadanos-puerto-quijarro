-- App Ciudadana: añadir ubicación a los reportes existentes sin borrar datos.
alter table public.reports
  add column if not exists latitude double precision,
  add column if not exists longitude double precision,
  add column if not exists location_accuracy_m double precision,
  add column if not exists location_captured_at timestamptz;

-- Validación geográfica básica: coordenadas dentro de rangos válidos.
alter table public.reports
  drop constraint if exists reports_latitude_range,
  add constraint reports_latitude_range check (latitude is null or latitude between -90 and 90),
  drop constraint if exists reports_longitude_range,
  add constraint reports_longitude_range check (longitude is null or longitude between -180 and 180),
  drop constraint if exists reports_accuracy_nonnegative,
  add constraint reports_accuracy_nonnegative check (location_accuracy_m is null or location_accuracy_m >= 0);

comment on column public.reports.latitude is 'Latitud del punto confirmado por el ciudadano';
comment on column public.reports.longitude is 'Longitud del punto confirmado por el ciudadano';
comment on column public.reports.location_accuracy_m is 'Precisión estimada del GPS en metros; null si el punto fue ajustado manualmente';
comment on column public.reports.location_captured_at is 'Fecha y hora UTC de captura o confirmación de ubicación';
