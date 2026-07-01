# Entrega Python - Examen PDS 2026

Este paquete implementa la variante Python para el examen integrador de PDS con la opcion de monitoreo de rodamiento (senal sintetica fs=1000 Hz).

## Estructura principal

- 01_informe: borrador del informe, tabla comparativa y bibliografia IEEE.
- 02_scripts_python: scripts de simulacion y analisis.
- 03_agente_ia: agente de decision por reglas y escenarios.
- 04_codigo_embebido: codigo ilustrativo ESP32 + documentacion.
- 05_graficos: salida PNG o fallback CSV.

## Ejecucion

Desde la raiz del repositorio:

```bash
python entrega_python/02_scripts_python/main.py
python entrega_python/03_agente_ia/agente_decision.py
```

## Sin dependencias extra

- No se instalan paquetes.
- Si scipy no esta disponible, se usa diseno/filtrado fallback con numpy.
- Si matplotlib no esta disponible, se intenta generar PNG via gnuplot.
- Si no hay matplotlib ni gnuplot, se generan CSV y README_FALTANTES.md en 05_graficos.

## Artefactos esperados

- run_log: entrega_python/02_scripts_python/run_log.md
- resultados del agente: entrega_python/03_agente_ia/resultados_agente.md
- graficos: entrega_python/05_graficos/

## Pendientes no automatizables

- 07_video: grabar video de presentacion y demostracion (guion base en 07_video/guion_video_presentacion.txt).
- 08_presentacion: armar diapositivas finales a partir de 08_presentacion/estructura_presentacion.txt.
