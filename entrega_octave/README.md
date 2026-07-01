# Entrega GNU Octave - Examen Parcial Integrador PDS 2026

## Objetivo
Implementar y comparar filtros FIR/IIR para una senal sintetica de vibracion con fs=1000 Hz, mas un agente de decision y una referencia de implementacion embebida.

## Estructura
- 01_informe: borradores en Markdown para informe final.
- 02_scripts_octave: scripts reproducibles en GNU Octave.
- 03_agente_ia: agente basado en reglas y evidencias de validacion.
- 04_codigo_embebido: referencia para ESP32 (simulada/documentada).
- 05_graficos: graficos PNG generados al ejecutar main.

## Ejecucion
Desde la raiz del repositorio:

```bash
octave --eval "addpath('entrega_octave/02_scripts_octave'); main"
```

Si `octave` no esta en PATH, usar la ruta absoluta detectada en este entorno:

```bash
"C:/Users/fernando/AppData/Local/Programs/GNU Octave/Octave-11.3.0/mingw64/bin/octave-cli.exe" --quiet --eval "addpath('entrega_octave/02_scripts_octave'); main"
```

Alternativa en consola interactiva de Octave:

```octave
addpath('entrega_octave/02_scripts_octave');
main;
```

## Salidas esperadas
- Graficos PNG en 05_graficos.
- Actualizacion de:
  - 02_scripts_octave/run_log.md
  - 03_agente_ia/resultados_agente.md
  - 01_informe/tabla_comparativa_fir_iir.md

Nota de entorno actual:
- Las metricas, tabla y resultados del agente se generan correctamente.
- En terminal headless el backend nativo puede fallar, pero el proyecto ya incluye
  fallback externo con gnuplot para exportar PNG.
- Estado validado: se generaron las 7 figuras en `05_graficos/`.

## Restricciones aplicadas
- Sin descargas externas.
- Codigo y documentos en ASCII.
- Compatibilidad orientada a GNU Octave 7.x.

## Evidencias no automatizables pendientes
- 07_video: grabacion de presentacion/demostracion (guion base en 07_video/guion_video_presentacion.txt).
- 08_presentacion: diapositivas finales para defensa (estructura base en 08_presentacion/estructura_presentacion.txt).
