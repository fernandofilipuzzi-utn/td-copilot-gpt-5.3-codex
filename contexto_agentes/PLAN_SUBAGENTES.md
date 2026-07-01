# Plan de Subagentes Independientes

## Subagente 1: DSP Python + Documentacion Tecnica
Especialidad requerida:
- Procesamiento digital de senales en Python (NumPy/SciPy/Matplotlib si disponible).
- Analisis cuantitativo (SNR, RMSE, FFT/PSD).
- Redaccion tecnica estructurada para informe.

Responsabilidades:
- Construir la variante Python en entrega_python/.
- Implementar diseno FIR e IIR y comparacion.
- Implementar agente de decision por reglas en Python.
- Generar graficos y reporte markdown.

## Subagente 2: DSP GNU Octave + Validacion de Scripts .m
Especialidad requerida:
- DSP en Octave/MATLAB (fir1, butter, freqz, grpdelay, zplane, pwelch/fft).
- Automatizacion de exportacion de graficos.
- Redaccion de resultados tecnicos para informe.

Responsabilidades:
- Construir la variante Octave en entrega_octave/.
- Implementar diseno FIR e IIR y comparacion.
- Implementar agente de decision por reglas en Octave.
- Ejecutar scripts en Octave y registrar conclusiones.

## Orquestacion
- Ambos subagentes trabajan sobre la misma opcion de aplicacion para comparabilidad.
- Se consolidan resultados en README por cada entrega.
- Pendientes no automatizables (video, defensa oral, pptx final) quedan documentados.
