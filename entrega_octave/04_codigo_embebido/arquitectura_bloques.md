# Arquitectura de Bloques - Implementacion Embebida

## Diagrama textual

```text
[Acelerometro MEMS]
        |
        v
[ADC ESP32 @ 1 kHz]
        |
        v
[Normalizacion / Preprocesado]
        |
        +------------------------------+
        |                              |
        v                              v
 [Filtro FIR]                     [Filtro IIR]
 (fase lineal)               (menor costo comput.)
        |                              |
        +--------------+---------------+
                       |
                       v
            [Salida serial / log]
                       |
                       v
         [Visualizacion / telemetria]
```

## Bloques funcionales
- Captura: toma de muestras uniformes con temporizacion fija.
- DSP: ruta FIR o IIR segun politica del sistema.
- Comunicacion: streaming de datos para diagnostico.
- Supervision: comprobacion de saturacion, deriva DC y overruns.

## Estrategia de muestreo y buffers
- Muestreo por timer periodico (1 ms) para minimizar jitter.
- ISR corta: adquiere y filtra una muestra, luego encola salida.
- Envio serial fuera de ISR para no comprometer tiempo real.
- Buffer circular para FIR y registros de estado para IIR.

## Decision de arquitectura
- Si prioridad es forma de onda y fase: usar FIR.
- Si prioridad es latencia y RAM: usar IIR.
