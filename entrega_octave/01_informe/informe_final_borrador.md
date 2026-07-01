# Informe Final Borrador - Examen Parcial Integrador PDS 2026 (GNU Octave)

## Caratula
- Asignatura: Procesamiento Digital de Senales
- Evaluacion: Examen Parcial Integrador PDS 2026
- Variante: GNU Octave
- Caso de uso: Monitoreo de condicion de rodamiento con acelerometro MEMS

## Resumen ejecutivo
Se diseno e implemento una solucion de PDS para separar componentes utiles (10-200 Hz) en una senal de vibracion con fs=1000 Hz, bajo presencia de interferencia en 350 Hz y ruido blanco. Se compararon un filtro FIR de fase lineal y un filtro IIR de menor orden efectivo. Se calcularon metricas SNR y RMSE, se validaron escenarios del agente de decision y se generaron las figuras PNG requeridas para el informe. En entorno headless, la exportacion grafica se resolvio con fallback externo a gnuplot. Tambien se incluyo una propuesta de implementacion embebida en ESP32.

## Indice
1. Marco teorico
2. Analisis del problema
3. Diseno de filtros
4. Simulacion
5. Agente IA / sistema experto
6. Implementacion embebida
7. Conclusiones
8. Bibliografia

## Marco teorico
En PDS, los filtros FIR permiten fase lineal y estabilidad inherente, a costa de mayor orden para pendientes pronunciadas. Los filtros IIR logran transiciones mas abruptas con menor complejidad, pero pueden introducir distorsion de fase. Para evaluacion objetiva se usan metricas como SNR y RMSE en relacion a una referencia limpia.

## Analisis del problema
### Contexto de aplicacion
Se adopta monitoreo de rodamientos con acelerometro MEMS. El objetivo es conservar informacion util entre 10 y 200 Hz y atenuar contenido de alta frecuencia (>300 Hz).

### Modelo de senal
Se sintetiza:
- Util 1: seno 30 Hz
- Util 2: seno 120 Hz
- Interferencia: seno 350 Hz
- Ruido: blanco gaussiano

Frecuencia de muestreo: 1000 Hz.

## Diseno de filtros
### FIR
- Tipo: pasa banda por sinc ventaneado (Hamming)
- Orden: 300 (301 coeficientes)
- Ventaja: fase casi lineal y control temporal.

### IIR
- Tipo: pasa banda por cascada biquad HP+LP (aprox Butterworth)
- Orden total: 4
- Ventaja: menor costo computacional y menor latencia.

## Simulacion
Se ejecuta `main.m` para:
- generar senal,
- aplicar filtros,
- calcular metricas,
- guardar graficos PNG,
- validar agente.

Graficos generados:
1. Dominio temporal (entrada/salida)
2. Espectros
3. Respuesta en frecuencia FIR
4. Respuesta en frecuencia IIR
5. Respuesta al impulso
6. Retardo de grupo
7. Mapa polos-ceros IIR

Estado de esta sesion: `main.m` ejecutado con exito usando Octave 11.3.0
(invocado por ruta absoluta). Resultado del pipeline: `SUCCESS_WITH_GNUPLOT_FALLBACK`.
Los graficos PNG fueron generados correctamente con fallback externo gnuplot.

Metricas obtenidas en la corrida real:
- SNR entrada: 3.1270 dB
- SNR salida FIR: 12.9372 dB
- SNR salida IIR: 6.1362 dB
- RMSE FIR: 0.172471
- RMSE IIR: 0.377371
- Reduccion de tono 350 Hz FIR: 75.3203 dB
- Reduccion de tono 350 Hz IIR: 17.3435 dB

Interpretacion:
- FIR supera claramente a IIR en rechazo de interferencia y SNR de salida.
- IIR mantiene ventaja de costo computacional y latencia.
- Para esta aplicacion (analisis de condicion), FIR es la opcion recomendada
	si la plataforma embebida dispone de recursos suficientes.

Graficos exportados en `05_graficos/`:
- 01_time_domain.png
- 02_spectrum.png
- 03_fir_response.png
- 04_iir_response.png
- 05_impulse_responses.png
- 06_group_delay.png
- 07_iir_pole_zero.png

Resultados cuantitativos detallados en:
- `02_scripts_octave/run_log.md`
- `01_informe/tabla_comparativa_fir_iir.md`

## Agente IA / sistema experto
Se implemento `03_agente_ia/agente_decision.m` con reglas IF-THEN sobre:
- requerimiento de fase lineal,
- RAM y MIPS disponibles,
- latencia maxima,
- SNR de entrada,
- necesidad de transicion abrupta.

La validacion usa `03_agente_ia/escenarios_prueba.csv` (>=3 casos) y produce `03_agente_ia/resultados_agente.md`.

Resultado actual del agente sobre 4 escenarios:
- Exactitud: 75.00% (3/4 aciertos).
- Mismatch detectado: ESC_03 (esperado FIR, predicho IIR).
- Accion recomendada: aumentar el peso de la regla de fase lineal cuando sea requisito estricto.

## Implementacion embebida
Se entrega codigo de referencia para ESP32 en `04_codigo_embebido/filtro_embebido_esp32.ino` con:
- ruta FIR por convolucion,
- ruta IIR por ecuacion en diferencias,
- seleccion por compilacion.

Se complementa con:
- `04_codigo_embebido/pseudocodigo_filtrado.md`
- `04_codigo_embebido/arquitectura_bloques.md`

## Conclusiones
- FIR e IIR satisfacen el objetivo de mitigar interferencia de alta frecuencia.
- FIR aporta mejor control de fase para analisis de forma de onda.
- IIR reduce complejidad y latencia, ventajoso en hardware con recursos limitados.
- La recomendacion final debe tomar en cuenta restricciones embebidas, no solo metrica de laboratorio.

## Bibliografia
Ver `01_informe/bibliografia_ieee.md`.

## Anexos
- Pendiente: video en `07_video/`
- Pendiente: presentacion en `08_presentacion/`
