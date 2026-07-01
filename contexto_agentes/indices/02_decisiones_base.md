# Decisiones Base para Resolver Rapido y Reproducible

## Opcion de aplicacion elegida
Opcion B (ANEXO I): Monitoreo de condicion de rodamiento con acelerometro MEMS.

## Razon
- Senal con interpretacion fisica clara.
- Frecuencia de muestreo manejable (1 kHz).
- Facil de simular sin depender de hardware.
- Permite comparar FIR e IIR de manera objetiva.

## Modelo de senal sintetica
x[n] = componente_util(30 Hz + 120 Hz) + interferencia(350 Hz) + ruido blanco

## Especificaciones propuestas
- fs = 1000 Hz
- Banda pasante aproximada: 10 a 200 Hz
- Rechazo fuerte por encima de 280-300 Hz
- Rp <= 1 dB, As >= 40 dB

## Diseno base
- FIR pasa banda por ventana Hamming (lineal en fase).
- IIR Butterworth (orden minimo por especificaciones).

## Modulo IA
Sistema de reglas IF-THEN con variables:
- fs, RAM, MIPS, fase lineal, SNR de entrada, latencia, pendiente.
Salidas:
- recomendacion FIR/IIR
- estructura sugerida
- justificacion tecnica

## Implementacion embebida
- Objetivo: ESP32 simulado (o equivalente) con representacion float32.
- Entrega: codigo C++/Arduino ilustrativo + pseudocodigo + diagrama de bloques textual.
