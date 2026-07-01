# Arquitectura de bloques (texto)

## Cadena de adquisicion y procesamiento
1. Sensor MEMS (aceleracion) -> ADC del ESP32.
2. Normalizacion y centrado de muestra.
3. Bloque de filtrado digital (FIR o IIR).
4. Extraccion de metrica (RMS, energia por banda).
5. Canal de salida (UART/WiFi) para monitoreo.

## Diagrama textual

```text
[MEMS ACC]
    |
    v
[ADC 1 kHz] -> [Preprocesado] -> [Filtro FIR/IIR] -> [Metricas] -> [Comunicacion]
```

## Criterios de seleccion de bloque de filtro
- FIR: mejor fase, mayor costo computacional.
- IIR: menor costo, fase no lineal.
- La seleccion final depende de reglas del agente y resultados de SNR/RMSE.
