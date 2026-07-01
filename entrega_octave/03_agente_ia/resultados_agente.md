# Resultados del Agente de Decision

Validacion automatica de escenarios en Octave.

- Escenarios evaluados: 4
- Exactitud respecto a expectativa: 75.00%

| ID | Esperado | Predicho | FIR score | IIR score | Match |
|---|---|---|---:|---:|---|
| ESC_01 | FIR | FIR | 7 | 0 | SI |
| ESC_02 | IIR | IIR | 0 | 9 | SI |
| ESC_03 | FIR | IIR | 4 | 6 | NO |
| ESC_04 | IIR | IIR | 1 | 8 | SI |

## Justificaciones

- **ESC_01**: Linear phase required: FIR preferred. Enough resources for FIR convolution. Latency budget allows FIR group delay. Moderate transition: FIR still practical. Very noisy input: FIR linear phase can preserve waveform.
- **ESC_02**: Linear phase not mandatory: IIR acceptable. Tight resources (RAM/MIPS): IIR preferred. Strict latency target: IIR preferred. Steep transition requested: IIR usually lower order. Input SNR acceptable: IIR distortions may be tolerable.
- **ESC_03**: Linear phase required: FIR preferred. Tight resources (RAM/MIPS): IIR preferred. Latency budget allows FIR group delay. Steep transition requested: IIR usually lower order. Input SNR acceptable: IIR distortions may be tolerable.
- **ESC_04**: Linear phase not mandatory: IIR acceptable. Tight resources (RAM/MIPS): IIR preferred. Strict latency target: IIR preferred. Steep transition requested: IIR usually lower order. Very noisy input: FIR linear phase can preserve waveform.
