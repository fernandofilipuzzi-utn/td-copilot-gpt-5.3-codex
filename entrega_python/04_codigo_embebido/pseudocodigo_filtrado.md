# Pseudocodigo de Filtrado Embebido

## Objetivo
Aplicar en tiempo real el filtro recomendado por el agente (FIR o IIR)
con muestreo fijo de 1 kHz y telemetria de diagnostico.

## Flujo general
1. Inicializar ADC, UART, timer periodico y buffers.
2. Cargar coeficientes en memoria (flash -> RAM).
3. Ejecutar filtrado por interrupcion de timer cada 1 ms.
4. Enviar datos en segundo plano (fuera de ISR).
5. Calcular estadisticos por bloque (RMS, pico, media).

## Pseudocodigo principal

```text
setup():
    configurar_adc(12_bits)
    configurar_uart(115200)
    configurar_timer(1_ms)
    inicializar_buffers()
    modo <- leer_config_agente()      # FIR o IIR

timer_ISR():
    x <- normalizar(leer_adc())

    si modo == FIR:
        y <- aplicar_fir_circular(x)
    si no:
        y <- aplicar_iir_recursivo(x)

    push_fifo_telemetria(x, y)
    push_buffer_bloque(y)

loop():
    mientras fifo_telemetria_no_vacia:
        enviar_uart_csv(x, y)

    si bloque_completo:
        rms <- calcular_rms(buffer_bloque)
        pico <- calcular_pico(buffer_bloque)
        enviar_resumen(rms, pico)
        limpiar_bloque()
```

## Rutina FIR (buffer circular)
```text
aplicar_fir_circular(x):
    xbuf[idx] <- x
    acc <- 0
    p <- idx
    para k = 0 .. N-1:
        acc <- acc + b[k] * xbuf[p]
        p <- p - 1
        si p < 0: p <- N-1
    idx <- (idx + 1) mod N
    retornar acc
```

## Rutina IIR (ecuacion en diferencias)
```text
aplicar_iir_recursivo(x):
    desplazar_derecha(x_hist)
    x_hist[0] <- x

    y <- sum(b[i] * x_hist[i]) - sum(a[j] * y_hist[j-1], j=1..M)

    desplazar_derecha(y_hist)
    y_hist[0] <- y
    retornar y
```

## Validaciones recomendadas
1. Confirmar jitter de muestreo y ausencia de overruns.
2. Verificar clipping/saturacion del ADC.
3. Comparar FFT embebida con simulacion de referencia.
4. Medir latencia extremo a extremo y uso de CPU.
