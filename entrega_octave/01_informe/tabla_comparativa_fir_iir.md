# Tabla Comparativa FIR vs IIR

Contexto: opcion de monitoreo de rodamientos, fs=1000 Hz, componentes utiles en 30/120 Hz e interferencia en 350 Hz.

| Criterio | FIR | IIR |
|---|---:|---:|
| Tipo | FIR band-pass (windowed sinc) | IIR band-pass (HP biquad + LP biquad) |
| Orden aproximado | 300 | 4 |
| SNR salida [dB] | 12.9372 | 6.1362 |
| RMSE vs referencia limpia | 0.172471 | 0.377371 |
| Reduccion tono 350 Hz [dB] | 75.3203 | 17.3435 |
| Fase lineal | SI | NO (aprox) |
| Costo computacional | Alto | Medio/Bajo |

## Observaciones

- FIR prioriza fidelidad temporal por fase casi lineal.
- IIR ofrece menor orden efectivo con respuesta mas compacta.
- La recomendacion final depende de restricciones embebidas (latencia y RAM).
