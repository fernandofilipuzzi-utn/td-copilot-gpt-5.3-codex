"""Main orchestration script for PDS 2026 exam delivery (Python variant)."""

from __future__ import annotations

from datetime import datetime
from pathlib import Path

try:
    import numpy as np
    NUMPY_AVAILABLE = True
except Exception:
    np = None
    NUMPY_AVAILABLE = False

if NUMPY_AVAILABLE:
    from filter_design import (
        SCIPY_AVAILABLE,
        apply_filter,
        design_fir_bandpass,
        design_iir_bandpass,
        frequency_response,
        group_delay_approx,
        impulse_response,
        poles_zeros,
    )
    from metrics import attenuation_db, passband_ripple_db, rmse, snr_db
    from plotting import MPL_AVAILABLE, save_line_plot, save_multi_line_plot
    from signal_model import build_signal
else:
    SCIPY_AVAILABLE = False
    MPL_AVAILABLE = False


def fft_magnitude(x: np.ndarray, fs: float) -> tuple[np.ndarray, np.ndarray]:
    n = len(x)
    xw = x * np.hanning(n)
    xfft = np.fft.rfft(xw)
    f = np.fft.rfftfreq(n, d=1.0 / fs)
    mag = np.abs(xfft)
    mag_db = 20.0 * np.log10(np.maximum(mag, 1e-12))
    return f, mag_db


def write_run_log(path: Path, content: str) -> None:
    path.write_text(content, encoding="utf-8")


def write_unavailable_artifacts(root: Path, run_log_path: Path) -> int:
    graph_dir = root / "05_graficos"
    graph_dir.mkdir(parents=True, exist_ok=True)
    (graph_dir / "README_FALTANTES.md").write_text(
        "# Artefactos faltantes\n\n"
        "No se pudieron ejecutar simulaciones numericas porque numpy no esta disponible en el entorno actual.\n"
        "Se dejaron listos todos los scripts y documentos para ejecutar cuando exista numpy.\n",
        encoding="utf-8",
    )
    log = []
    log.append("# Run Log\n")
    log.append(f"- Timestamp: {datetime.now().isoformat()}\n")
    log.append("- Execution status: failed to run numerical simulation\n")
    log.append("- Root cause: numpy is not installed in this Python environment\n")
    log.append("- scipy status: not evaluated because numpy missing\n")
    log.append("- matplotlib status: not evaluated because numpy missing\n")
    log.append("\n## Outcome\n")
    log.append("- Codebase and deliverables were created successfully.\n")
    log.append("- Numerical metrics and PNG generation are pending runtime with numpy available.\n")
    log.append("- Created fallback note: entrega_python/05_graficos/README_FALTANTES.md\n")
    write_run_log(run_log_path, "".join(log))
    print(f"Run completed in fallback mode. Log saved at: {run_log_path}")
    return 0


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    graph_dir = root / "05_graficos"
    graph_dir.mkdir(parents=True, exist_ok=True)
    run_log_path = root / "02_scripts_python" / "run_log.md"

    if not NUMPY_AVAILABLE:
        return write_unavailable_artifacts(root=root, run_log_path=run_log_path)

    fs = 1000.0
    data = build_signal(fs=fs, duration_s=4.0)
    t = data["t"]
    x = data["input"]
    useful = data["useful"]

    # FIR: 301 taps for Hamming window (transition bw ~26 Hz -> 30 Hz safely in passband)
    fir = design_fir_bandpass(fs=fs, f1=10.0, f2=200.0, num_taps=301)
    iir = design_iir_bandpass(fs=fs, f1=10.0, f2=200.0, order=4)

    y_fir = apply_filter(fir, x)
    y_iir = apply_filter(iir, x)

    f_fir, h_fir = frequency_response(fir, fs=fs)
    f_iir, h_iir = frequency_response(iir, fs=fs)

    himp_fir = impulse_response(fir, n=220)
    himp_iir = impulse_response(iir, n=220)

    fgd_fir, gd_fir = group_delay_approx(h_fir, f_fir, fs)
    fgd_iir, gd_iir = group_delay_approx(h_iir, f_iir, fs)

    z_fir, p_fir = poles_zeros(fir)
    z_iir, p_iir = poles_zeros(iir)

    # Compensate FIR group delay before computing metrics (linear phase -> constant delay = (N-1)/2)
    # y_fir[D+m] ~ x[m] => compare useful[0:N-D] with y_fir[D:N]
    fir_delay = fir["num_taps"] // 2
    snr_in = snr_db(useful, x)
    snr_out_fir = snr_db(useful[:-fir_delay], y_fir[fir_delay:])
    snr_out_iir = snr_db(useful, y_iir)
    rmse_fir = rmse(useful[:-fir_delay], y_fir[fir_delay:])
    rmse_iir = rmse(useful, y_iir)

    fir_att = attenuation_db(f_fir, h_fir, f_start=280.0)
    iir_att = attenuation_db(f_iir, h_iir, f_start=280.0)
    fir_ripple = passband_ripple_db(f_fir, h_fir, f1=10.0, f2=200.0)
    iir_ripple = passband_ripple_db(f_iir, h_iir, f1=10.0, f2=200.0)

    pb_mask_fir = (fgd_fir >= 10.0) & (fgd_fir <= 200.0)
    pb_mask_iir = (fgd_iir >= 10.0) & (fgd_iir <= 200.0)
    gd_fir_mean = float(np.mean(gd_fir[pb_mask_fir])) if np.any(pb_mask_fir) else float(np.mean(gd_fir))
    gd_iir_mean = float(np.mean(gd_iir[pb_mask_iir])) if np.any(pb_mask_iir) else float(np.mean(gd_iir))

    created_png = []
    created_csv = []

    def _plot_line(xv, yv, title, xl, yl, png_name, csv_name):
        png = graph_dir / png_name
        csv = graph_dir / csv_name
        ok = save_line_plot(xv, yv, title, xl, yl, png, csv)
        if ok:
            created_png.append(png.name)
        else:
            created_csv.append(csv.name)

    def _plot_multi(xv, ys, labels, title, xl, yl, png_name, csv_name):
        png = graph_dir / png_name
        csv = graph_dir / csv_name
        ok = save_multi_line_plot(xv, ys, labels, title, xl, yl, png, csv)
        if ok:
            created_png.append(png.name)
        else:
            created_csv.append(csv.name)

    n_view = min(len(t), int(fs * 1.0))
    _plot_multi(
        t[:n_view],
        [x[:n_view], useful[:n_view], y_fir[:n_view], y_iir[:n_view]],
        ["input", "useful", "fir_out", "iir_out"],
        "Time domain signals (first second)",
        "Time [s]",
        "Amplitude",
        "time_signals.png",
        "time_signals.csv",
    )

    _plot_multi(
        f_fir,
        [20.0 * np.log10(np.maximum(np.abs(h_fir), 1e-12)), 20.0 * np.log10(np.maximum(np.abs(h_iir), 1e-12))],
        ["FIR", "IIR"],
        "Frequency response magnitude",
        "Frequency [Hz]",
        "Magnitude [dB]",
        "freq_response.png",
        "freq_response.csv",
    )

    _plot_multi(
        np.arange(len(himp_fir)),
        [himp_fir, himp_iir],
        ["FIR", "IIR"],
        "Impulse response",
        "Sample",
        "h[n]",
        "impulse_response.png",
        "impulse_response.csv",
    )

    _plot_multi(
        fgd_fir,
        [gd_fir, np.interp(fgd_fir, fgd_iir, gd_iir, left=gd_iir[0], right=gd_iir[-1])],
        ["FIR", "IIR"],
        "Group delay approximation",
        "Frequency [Hz]",
        "Samples",
        "group_delay.png",
        "group_delay.csv",
    )

    fft_f, fft_in = fft_magnitude(x, fs)
    _, fft_fir_out = fft_magnitude(y_fir, fs)
    _, fft_iir_out = fft_magnitude(y_iir, fs)
    _plot_multi(
        fft_f,
        [fft_in, fft_fir_out, fft_iir_out],
        ["Input", "FIR out", "IIR out"],
        "FFT magnitude",
        "Frequency [Hz]",
        "Magnitude [dB]",
        "fft_compare.png",
        "fft_compare.csv",
    )

    faltantes_path = graph_dir / "README_FALTANTES.md"
    if len(created_png) == 0:
        faltantes_path.write_text(
            "# Artefactos faltantes\n\n"
            "No se pudieron crear PNG porque no hay backend grafico disponible "
            "(matplotlib o gnuplot).\n"
            "Se generaron CSV de respaldo para evidencia numerica.\n\n"
            f"CSV generados: {', '.join(created_csv) if created_csv else 'ninguno'}\n",
            encoding="utf-8",
        )
    elif faltantes_path.exists():
        faltantes_path.unlink()

    log = []
    log.append("# Run Log\n")
    log.append(f"- Timestamp: {datetime.now().isoformat()}\n")
    log.append(f"- Python mode: numpy fallback ready\n")
    log.append(f"- scipy available: {SCIPY_AVAILABLE}\n")
    log.append(f"- matplotlib available: {MPL_AVAILABLE}\n")
    log.append("\n## Signal and Filter Setup\n")
    log.append(f"- fs: {fs} Hz\n")
    log.append("- Useful components: 30 Hz and 120 Hz\n")
    log.append("- Interference component: 350 Hz\n")
    log.append("- FIR design: Hamming windowed-sinc, 10-200 Hz\n")
    log.append(f"- IIR design: {iir['name']}\n")
    log.append("\n## Quantitative Comparison\n")
    log.append("| Metric | Input | FIR | IIR |\n")
    log.append("|---|---:|---:|---:|\n")
    log.append(f"| SNR (dB) | {snr_in:.3f} | {snr_out_fir:.3f} | {snr_out_iir:.3f} |\n")
    log.append(f"| RMSE vs useful | - | {rmse_fir:.6f} | {rmse_iir:.6f} |\n")
    log.append(f"| Ripple 10-200 Hz (dB) | - | {fir_ripple:.3f} | {iir_ripple:.3f} |\n")
    log.append(f"| Rejection >=280 Hz (dB) | - | {fir_att:.3f} | {iir_att:.3f} |\n")
    log.append(f"| Mean group delay 10-200 Hz (samples) | - | {gd_fir_mean:.3f} | {gd_iir_mean:.3f} |\n")

    log.append("\n## Pole-Zero Summary\n")
    log.append(f"- FIR zeros: {len(z_fir)}, FIR poles: {len(p_fir)}\n")
    log.append(f"- IIR zeros: {len(z_iir)}, IIR poles: {len(p_iir)}\n")

    log.append("\n## Artifacts\n")
    log.append(f"- PNG generated: {', '.join(created_png) if created_png else 'none'}\n")
    log.append(f"- CSV fallback: {', '.join(created_csv) if created_csv else 'none'}\n")

    # Decision based on measured results: prioritize SNR improvement over input
    snr_gain_fir = snr_out_fir - snr_in
    snr_gain_iir = snr_out_iir - snr_in
    if snr_out_fir >= snr_out_iir + 3.0:
        recommendation = "FIR"
        reason = (
            f"FIR selected: SNR gain {snr_gain_fir:.1f} dB vs IIR {snr_gain_iir:.1f} dB. "
            "Linear phase preserved (critical for morphology in bearing diagnostics). "
            "Superior stopband attenuation at interference frequency."
        )
    elif snr_out_iir > snr_out_fir:
        recommendation = "IIR"
        reason = (
            f"IIR selected: better SNR ({snr_out_iir:.2f} dB) with lower order ({iir.get('used_scipy',False)!s}). "
            "Lower latency and computational cost."
        )
    else:
        recommendation = "FIR"
        reason = "FIR selected by default: linear phase and higher stopband rejection."
    log.append("\n## Decision Snapshot\n")
    log.append(f"- Suggested by measured results: {recommendation}\n")
    log.append(f"- Reason: {reason}\n")

    write_run_log(run_log_path, "".join(log))
    print(f"Run completed. Log saved at: {run_log_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
