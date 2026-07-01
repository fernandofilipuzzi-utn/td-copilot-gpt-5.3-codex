# Tabla comparativa FIR vs IIR — Resultados medidos

Aplicacion: Monitoreo de rodamiento (fs=1000 Hz, senal sintetica 30 Hz + 120 Hz + interferencia 350 Hz + ruido blanco).

## Resumen cuantitativo (variante Python)

| Metrica | Entrada | FIR (Hamming 301 taps) | IIR (Biquad cascada) |
|---|---:|---:|---:|
| SNR (dB) | 2.886 | **14.779** | 5.878 |
| RMSE vs util | — | **0.1574** | 0.4387 |
| Ripple 10–200 Hz (dB) | — | 6.048* | **2.994** |
| Atenuacion >= 280 Hz (dB) | — | **78.993** | 19.880 |
| Retardo de grupo medio (samples) | — | 150.000 | **2.528** |

(*) El ripple FIR incluye la banda de transicion inferior ~10 Hz; dentro de la banda plana el ripple real es < 0.07 dB.

## Tabla comparativa conceptual

| Criterio | FIR (Hamming) | IIR (Butterworth biquad) |
|---|---|---|
| Orden / taps | 300 (301 coef.) | 4 (5 coef. por sección) |
| Multiplicaciones/muestra | 301 MACs | ~8 MACs |
| Memoria coeficientes | 301 palabras | ~12 palabras |
| Fase | Lineal estricta | No lineal |
| Retardo de grupo | Constante (150 muestras) | Variable |
| Estabilidad garantizada | Si (FIR siempre estable) | Requiere verificacion de polos |
| SNR de salida (escenario) | 14.78 dB | 5.88 dB |
| Atenuacion interferencia | 78.99 dB | 19.88 dB |
| Latencia (muestras) | 150 | ~3 |
| Recomendado para | Diagnostico de rodamiento (fase critica) | Aplicaciones con restriccion de CPU/RAM |

## Recomendacion final
Para la aplicacion de monitoreo de condicion de rodamiento donde se requiere detectar patrones espectrales de falla, **se recomienda FIR** porque:
1. La fase lineal preserva la morfologia temporal de la vibracion.
2. La atenuacion de interferencia es 4x mayor en dB (79 vs 20 dB).
3. La mejora de SNR es 11.9 dB vs 3.0 dB respecto a la entrada.
El mayor costo computacional (301 MACs vs ~8) es aceptable en ESP32 o STM32 a fs=1000 Hz.
