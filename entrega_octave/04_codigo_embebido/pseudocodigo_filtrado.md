# Pseudocodigo de Filtrado Embebido (ESP32)

## Objetivo
Implementar un filtrado digital a fs = 1000 Hz sobre una senal de vibracion,
con dos rutas posibles:
- FIR lineal en fase (301 taps) para alta fidelidad.
- IIR biquad en cascada para baja latencia y bajo costo.

## Parametros base
- fs = 1000 Hz (T = 1 ms)
- Formato de coeficientes: float32
- Adquisicion: ADC 12 bits
- Salida: UART CSV (x,y)

## Flujo principal (alto nivel)
```text
setup():
   configurar_ADC(12_bits)
   configurar_UART(115200)
   cargar_coeficientes_FIR_o_IIR()
   inicializar_buffers_y_estados()
   configurar_timer_periodico(1_ms)

timer_ISR():
   x_raw <- leer_ADC()
   x <- normalizar_ADC(x_raw)         # rango aproximado [-1, 1]

   si modo_filtro == FIR:
      y <- procesar_FIR(x)
   si no:
      y <- procesar_IIR(x)

   encolar_salida(x, y)

loop():
   mientras hay_datos_en_cola:
      enviar_UART_csv(x, y)
```

## Ruta FIR (convolucion con buffer circular)
```text
procesar_FIR(x):
   xbuf[idx] <- x

   acc <- 0
   p <- idx
   para k en [0 .. N-1]:
      acc <- acc + b[k] * xbuf[p]
      p <- p - 1
      si p < 0: p <- N-1

   idx <- idx + 1
   si idx == N: idx <- 0

   retornar acc
```

## Ruta IIR (ecuacion en diferencias, forma directa)
```text
procesar_IIR(x):
   desplazar_derecha(x_hist)
   x_hist[0] <- x

   y <- 0
   para i en [0 .. Nb-1]:
      y <- y + b[i] * x_hist[i]
   para i en [1 .. Na-1]:
      y <- y - a[i] * y_hist[i-1]

   desplazar_derecha(y_hist)
   y_hist[0] <- y

   retornar y
```

## Control de tiempo real
1. Medir tiempo de ejecucion por muestra (us) y garantizar us < 1000.
2. Registrar overrun si ISR tarda mas que el periodo.
3. Priorizar ISR corta; enviar UART fuera de ISR cuando sea posible.

## Validacion minima requerida
1. Verificar fs real con timestamp o pin toggle.
2. Confirmar ausencia de clipping ADC.
3. Comparar FFT de salida embebida vs simulacion Octave/Python.
4. Cuantificar error (RMSE o diferencia de espectro) contra referencia.
