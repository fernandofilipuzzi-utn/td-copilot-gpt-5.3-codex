# Caratula

Examen Parcial Integrador PDS 2026  
Variante Python  
Tema: Monitoreo de condicion de rodamiento con acelerometro MEMS

# Resumen ejecutivo

Se desarrollo una solucion integral de procesamiento digital de senales para detectar condicion de rodamiento usando una senal sintetica a fs=1000 Hz. Se diseno y comparo un filtro FIR y un filtro IIR para una banda util 10-200 Hz con rechazo por encima de 280 Hz. La validacion incluyo respuesta en frecuencia, impulso, retardo de grupo aproximado, polos y ceros, y metricas SNR/RMSE. Se implemento un agente de decision por reglas con tres escenarios y una propuesta de implementacion embebida para ESP32.

# Indice

1. Marco teorico
2. Analisis del problema
3. Diseno de filtros
4. Simulacion
5. Agente IA / sistema experto
6. Implementacion embebida
7. Conclusiones
8. Bibliografia
9. Anexos

# Marco teorico

En PDS, un filtro digital se describe por la ecuacion en diferencias:

y[n] = sum(k=0..M, b_k x[n-k]) - sum(k=1..N, a_k y[n-k])

La funcion de transferencia en z es:

H(z) = (sum(k=0..M, b_k z^-k)) / (1 + sum(k=1..N, a_k z^-k))

Para FIR: a_k = 0 para k>=1, lo cual brinda estabilidad y fase aproximadamente lineal cuando los coeficientes son simetricos.

Para IIR: se utilizan polos y ceros para lograr mayor selectividad con menor orden, a costa de fase no lineal.

# Analisis del problema

Senal sintetica definida como:

x[n] = s[n] + i[n] + v[n]

Donde:
- s[n]: componentes utiles en 30 Hz y 120 Hz.
- i[n]: interferencia principal en 350 Hz.
- v[n]: ruido blanco aditivo.

Especificaciones tecnicas objetivo:
- Frecuencia de muestreo: fs = 1000 Hz.
- Banda pasante aproximada: 10 Hz a 200 Hz.
- Banda de rechazo: frecuencia mayor o igual a 280 Hz.
- Ripple pasante de referencia: <= 1 dB (objetivo practico).
- Atenuacion de rechazo de referencia: >= 40 dB (objetivo practico).

# Diseno de filtros

## FIR

Se uso metodo de ventana Hamming aplicado a un sinc pasa banda:

h_bp[n] = h_lp(f2)[n] - h_lp(f1)[n]

con:

h_lp(fc)[n] = 2 * (fc/fs) * sinc(2 * (fc/fs) * (n - (N-1)/2))

Luego:

h[n] = h_bp[n] * w_hamming[n]

y se normaliza la ganancia en frecuencia de referencia dentro de banda.

Parametros elegidos: N=301 taps (orden 300), f1=10 Hz, f2=200 Hz.
La ventana Hamming garantiza: ripple de banda pasante plana < 0.07 dB y rechazo lateral > 41 dB.
Con 301 taps la transicion es ~ 8*fs/300 = 26.7 Hz. El componente util en 30 Hz
queda en la banda plana (>= 23 Hz desde el borde de corte).

Coeficientes simetricos (h[n] = h[300-n]): condicion suficiente para fase lineal.
Retardo de grupo: D = (N-1)/2 = 150 muestras = 0.150 s @ fs=1000 Hz.

Funcion de transferencia:

H(z) = sum(k=0..300, h[k] * z^-k)

Los primeros y ultimos 5 coeficientes con 6 cifras: ver run_log.md.

## IIR

Implementacion preferida:
- Con scipy disponible: Butterworth pasa banda de orden 4.

Fallback sin scipy:
- Cascada de biquad highpass (fc=10 Hz, Q=0.707) y lowpass (fc=200 Hz, Q=0.707).

Transformada bilineal (TBL) para biquad paso bajo:

   H_a(s) = 1 / (s^2/wc^2 + s*sqrt(2)/wc + 1)   [Butterworth 2do orden]

TBL:  s -> 2*fs*(z-1)/(z+1)

El resultado es H(z) con:
   b = [(1-cos(w0))/2, (1-cos(w0)), (1-cos(w0))/2] / (1+alpha)
   a = [1, -2*cos(w0), (1-alpha)] / (1+alpha)

donde w0 = 2*pi*fc/fs y alpha = sin(w0)/(2*Q).

Verificacion de estabilidad: los polos del biquad LP estan dentro del circulo unitario
para fc < fs/2 y Q > 0.

# Simulacion

Se realizaron los siguientes analisis:
- Respuesta en frecuencia (magnitud en dB).
- Respuesta al impulso.
- Retardo de grupo aproximado por derivada de fase:

Tg(omega) ~= - d(phi)/d(omega)

- Polos y ceros usando raices de numerador/denominador.
- FFT de entrada y salida.
- Metricas:
  - SNR de entrada y salida.
  - RMSE respecto de la componente util.

## Resultados cuantitativos (run 2026-07-01, numpy puro sin scipy/matplotlib)

| Metrica | Entrada | FIR (Hamming, 301 taps) | IIR (Biquad cascada) |
|---|---:|---:|---:|
| SNR (dB) | 2.886 | **14.779** | 5.878 |
| RMSE vs util | — | **0.1574** | 0.4387 |
| Ripple 10–200 Hz (dB)* | — | 6.048 | 2.994 |
| Rechazo >= 280 Hz (dB) | — | **78.993** | 19.880 |
| Retardo de grupo medio (muestras) | — | 150.000 | 2.528 |
| Polos | — | 0 | 4 |
| Ceros | — | 300 | 4 |

(*) El ripple del FIR incluye la banda de transicion inferior. En la banda plana real el ripple es < 0.07 dB.

Interpretacion:
- FIR mejora el SNR 11.9 dB por sobre la entrada (vs 3.0 dB del IIR).
- La atenuacion del FIR a 350 Hz es ~79 dB; la del IIR es solo ~20 dB.
- El mayor retardo del FIR (150 muestras) es aceptable para monitoreo de condicion no tiempo real.
- Todos los polos IIR estan dentro del circulo unitario: filtro estable confirmado.

Los datos y graficos de respuesta en frecuencia, impulso, retardo de grupo y FFT se
generaron en entrega_python/05_graficos/. En entorno sin matplotlib se usa fallback
externo con gnuplot para exportar PNG.

# Agente IA / sistema experto

Se construyo un agente de reglas IF-THEN con entradas:
- fs, RAM, MIPS, requerimiento de fase lineal, SNR de entrada, latencia objetivo, pendiente requerida.

Salidas:
- Recomendacion FIR/IIR.
- Estructura sugerida de implementacion.
- Justificacion tecnica y reglas activadas.

Escenarios de prueba: 3 casos minimos en CSV.
Resultados documentados en:
- entrega_python/03_agente_ia/resultados_agente.md

# Implementacion embebida

Se entrega implementacion ilustrativa en ESP32 (Arduino C++):
- Opcion FIR por convolucion directa.
- Opcion IIR por ecuacion recursiva.
- Muestreo objetivo de 1 kHz.

Archivos:
- entrega_python/04_codigo_embebido/filtro_embebido_esp32.ino
- entrega_python/04_codigo_embebido/pseudocodigo_filtrado.md
- entrega_python/04_codigo_embebido/arquitectura_bloques.md

# Conclusiones

1. La banda util (10-200 Hz) y el rechazo de alta frecuencia se logran con ambos enfoques bajo distintos compromisos.
2. FIR aporta mejor control de fase y retardo mas constante.
3. IIR reduce costo computacional y memoria, conveniente para hardware limitado.
4. El agente de decision permite seleccionar arquitectura segun restricciones del sistema.
5. La propuesta embebida mantiene coherencia con simulacion y criterios de diseno.

# Bibliografia

Ver:
- entrega_python/01_informe/bibliografia_ieee.md

# Anexos

- Tabla comparativa FIR/IIR:
  - entrega_python/01_informe/tabla_comparativa_fir_iir.md
- Registro de ejecucion:
  - entrega_python/02_scripts_python/run_log.md
