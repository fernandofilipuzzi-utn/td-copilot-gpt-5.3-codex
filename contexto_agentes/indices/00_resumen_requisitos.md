# Resumen Ejecutivo de Consignas (Examen PDS 2026)

## Objetivo
Desarrollar una solucion integral de PDS que incluya:
- Diseno matematico de filtro FIR y filtro IIR.
- Simulacion y validacion computacional.
- Agente de decision (IA o sistema experto) para recomendar FIR/IIR.
- Implementacion embebida (real o simulada) del filtro elegido.

## Pasos obligatorios
1. Analisis de senal y especificaciones (fs, fp, fr, Rp, As, fase lineal).
2. Desarrollo matematico completo FIR e IIR.
3. Simulacion (respuesta frecuencia, fase, impulso, retardo de grupo, polos/ceros, FFT/PSD, SNR/RMSE).
4. Agente de decision con al menos 3 escenarios de validacion.
5. Implementacion embebida documentada (arquitectura, codigo, pruebas).

## Requisitos minimos de aprobacion (criticos)
- Desarrollo matematico completo FIR e IIR.
- Simulacion con graficas temporales y frecuenciales.
- Agente funcional con >=3 reglas.
- Implementacion embebida funcional (real o simulada).
- Comparacion cuantitativa FIR vs IIR.

## Restricciones utiles para esta resolucion
- Se construyen dos entregas: Python y GNU Octave.
- Se prioriza una opcion de senal viable y reproducible sin hardware real.
- Se documenta explicitamente el uso de IA y el aporte propio.
