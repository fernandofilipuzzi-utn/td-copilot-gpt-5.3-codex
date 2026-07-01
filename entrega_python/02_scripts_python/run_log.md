# Run Log
- Timestamp: 2026-07-01T17:24:13.830862
- Python mode: numpy fallback ready
- scipy available: False
- matplotlib available: False

## Signal and Filter Setup
- fs: 1000.0 Hz
- Useful components: 30 Hz and 120 Hz
- Interference component: 350 Hz
- FIR design: Hamming windowed-sinc, 10-200 Hz
- IIR design: IIR_BiquadCascade_Bandpass

## Quantitative Comparison
| Metric | Input | FIR | IIR |
|---|---:|---:|---:|
| SNR (dB) | 2.886 | 14.779 | 5.878 |
| RMSE vs useful | - | 0.157436 | 0.438728 |
| Ripple 10-200 Hz (dB) | - | 6.048 | 2.994 |
| Rejection >=280 Hz (dB) | - | 78.993 | 19.880 |
| Mean group delay 10-200 Hz (samples) | - | 150.000 | 2.528 |

## Pole-Zero Summary
- FIR zeros: 300, FIR poles: 0
- IIR zeros: 4, IIR poles: 4

## Artifacts
- PNG generated: time_signals.png, freq_response.png, impulse_response.png, group_delay.png, fft_compare.png
- CSV fallback: none

## Decision Snapshot
- Suggested by measured results: FIR
- Reason: FIR selected: SNR gain 11.9 dB vs IIR 3.0 dB. Linear phase preserved (critical for morphology in bearing diagnostics). Superior stopband attenuation at interference frequency.
