# Resultados del agente de decision

| Escenario | Recomendacion | Estructura sugerida | Razon | Reglas activadas |
|---|---|---|---|---|
| Industrial_hard_realtime | IIR | Cascade biquad IIR (SOS), float32 | Selected for low computational and memory cost. | R2: Tight resources -> favor IIR. | R3: Very low latency target -> favor IIR. | R5: Very noisy input -> prioritize robust attenuation. |
| Laboratorio_analisis_fase | FIR | Direct form FIR, symmetric coefficients | Selected for linear phase and predictable delay. | R1: Linear phase required -> favor FIR. | R4: High slope and enough resources -> FIR possible. |
| Balanceado_general | FIR | Direct form FIR, symmetric coefficients | Selected for linear phase and predictable delay. | No specific constraints triggered. |
