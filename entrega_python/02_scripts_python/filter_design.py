"""Filter design and analysis helpers with scipy optional fallback."""

from __future__ import annotations

import numpy as np

try:
    from scipy import signal as sp_signal  # type: ignore
    SCIPY_AVAILABLE = True
except Exception:
    sp_signal = None
    SCIPY_AVAILABLE = False


def _normalize_freq(freq_hz: float, fs: float) -> float:
    return freq_hz / (fs / 2.0)


def design_fir_bandpass(fs: float, f1: float = 10.0, f2: float = 200.0, num_taps: int = 101) -> dict:
    """Design FIR bandpass using Hamming-windowed sinc."""
    if num_taps % 2 == 0:
        num_taps += 1
    m = np.arange(num_taps) - (num_taps - 1) / 2.0
    fc1 = f1 / fs
    fc2 = f2 / fs

    h_lp2 = 2.0 * fc2 * np.sinc(2.0 * fc2 * m)
    h_lp1 = 2.0 * fc1 * np.sinc(2.0 * fc1 * m)
    h_bp = h_lp2 - h_lp1

    w = np.hamming(num_taps)
    b = h_bp * w

    f_ref = (f1 + f2) / 2.0
    omega = 2.0 * np.pi * f_ref / fs
    ejw = np.exp(-1j * omega * np.arange(num_taps))
    gain = np.abs(np.sum(b * ejw))
    if gain > 0:
        b = b / gain

    return {
        "name": "FIR_Hamming_Bandpass",
        "b": b,
        "a": np.array([1.0]),
        "num_taps": num_taps,
        "design_note": "Windowed-sinc FIR, linear phase.",
    }


def _biquad_lowpass(fs: float, fc: float, q: float = 0.70710678) -> tuple[np.ndarray, np.ndarray]:
    w0 = 2.0 * np.pi * fc / fs
    alpha = np.sin(w0) / (2.0 * q)
    c = np.cos(w0)

    b0 = (1.0 - c) / 2.0
    b1 = 1.0 - c
    b2 = (1.0 - c) / 2.0
    a0 = 1.0 + alpha
    a1 = -2.0 * c
    a2 = 1.0 - alpha

    b = np.array([b0, b1, b2]) / a0
    a = np.array([1.0, a1 / a0, a2 / a0])
    return b, a


def _biquad_highpass(fs: float, fc: float, q: float = 0.70710678) -> tuple[np.ndarray, np.ndarray]:
    w0 = 2.0 * np.pi * fc / fs
    alpha = np.sin(w0) / (2.0 * q)
    c = np.cos(w0)

    b0 = (1.0 + c) / 2.0
    b1 = -(1.0 + c)
    b2 = (1.0 + c) / 2.0
    a0 = 1.0 + alpha
    a1 = -2.0 * c
    a2 = 1.0 - alpha

    b = np.array([b0, b1, b2]) / a0
    a = np.array([1.0, a1 / a0, a2 / a0])
    return b, a


def design_iir_bandpass(fs: float, f1: float = 10.0, f2: float = 200.0, order: int = 4) -> dict:
    """Design IIR bandpass. Uses scipy Butterworth if available, else biquad cascade."""
    if SCIPY_AVAILABLE:
        wn = [_normalize_freq(f1, fs), _normalize_freq(f2, fs)]
        b, a = sp_signal.butter(order, wn, btype="bandpass")
        sos = sp_signal.tf2sos(b, a)
        return {
            "name": "IIR_Butterworth_Bandpass",
            "b": b,
            "a": a,
            "sos": sos,
            "design_note": f"Butterworth order {order} via scipy.",
            "used_scipy": True,
        }

    b_hp, a_hp = _biquad_highpass(fs=fs, fc=f1)
    b_lp, a_lp = _biquad_lowpass(fs=fs, fc=f2)

    b_total = np.convolve(b_hp, b_lp)
    a_total = np.convolve(a_hp, a_lp)
    sos = np.array([
        np.concatenate([b_hp, a_hp]),
        np.concatenate([b_lp, a_lp]),
    ])
    return {
        "name": "IIR_BiquadCascade_Bandpass",
        "b": b_total,
        "a": a_total,
        "sos": sos,
        "design_note": "Fallback: cascaded highpass+lowpass biquads (Butterworth-like).",
        "used_scipy": False,
    }


def lfilter_numpy(b: np.ndarray, a: np.ndarray, x: np.ndarray) -> np.ndarray:
    """Direct-form I filter implementation with a[0]=1 assumption."""
    b = np.asarray(b, dtype=float)
    a = np.asarray(a, dtype=float)
    x = np.asarray(x, dtype=float)

    if a[0] != 1.0:
        b = b / a[0]
        a = a / a[0]

    y = np.zeros_like(x, dtype=float)
    for n in range(len(x)):
        acc = 0.0
        for k in range(len(b)):
            if n - k >= 0:
                acc += b[k] * x[n - k]
        for k in range(1, len(a)):
            if n - k >= 0:
                acc -= a[k] * y[n - k]
        y[n] = acc
    return y


def sos_filter_numpy(sos: np.ndarray, x: np.ndarray) -> np.ndarray:
    """Filter signal through SOS with numpy fallback."""
    y = np.asarray(x, dtype=float)
    for sec in sos:
        b = sec[:3]
        a = sec[3:]
        y = lfilter_numpy(b, a, y)
    return y


def apply_filter(filter_def: dict, x: np.ndarray) -> np.ndarray:
    """Apply FIR/IIR filter with scipy if available, else numpy fallback."""
    b = filter_def["b"]
    a = filter_def["a"]

    if SCIPY_AVAILABLE:
        if "sos" in filter_def and filter_def["sos"] is not None:
            return sp_signal.sosfilt(filter_def["sos"], x)
        return sp_signal.lfilter(b, a, x)

    if "sos" in filter_def and filter_def["sos"] is not None:
        return sos_filter_numpy(filter_def["sos"], x)
    return lfilter_numpy(b, a, x)


def frequency_response(filter_def: dict, fs: float, n_fft: int = 4096) -> tuple[np.ndarray, np.ndarray]:
    """Compute frequency response H(f)."""
    b = np.asarray(filter_def["b"], dtype=float)
    a = np.asarray(filter_def["a"], dtype=float)

    if SCIPY_AVAILABLE:
        w, h = sp_signal.freqz(b=b, a=a, worN=n_fft, fs=fs)
        return w, h

    f = np.linspace(0.0, fs / 2.0, n_fft)
    omega = 2.0 * np.pi * f / fs
    ejw = np.exp(-1j * np.outer(omega, np.arange(max(len(a), len(b)))))

    b_pad = np.zeros(ejw.shape[1])
    a_pad = np.zeros(ejw.shape[1])
    b_pad[: len(b)] = b
    a_pad[: len(a)] = a

    num = ejw @ b_pad
    den = ejw @ a_pad
    h = np.divide(num, den, out=np.zeros_like(num), where=np.abs(den) > 1e-12)
    return f, h


def impulse_response(filter_def: dict, n: int = 200) -> np.ndarray:
    """Compute impulse response by filtering a unit impulse."""
    imp = np.zeros(n, dtype=float)
    imp[0] = 1.0
    return apply_filter(filter_def, imp)


def group_delay_approx(h: np.ndarray, f: np.ndarray, fs: float) -> tuple[np.ndarray, np.ndarray]:
    """Approximate group delay from unwrapped phase derivative."""
    phase = np.unwrap(np.angle(h))
    omega = 2.0 * np.pi * f / fs
    dphi = np.diff(phase)
    domega = np.diff(omega)
    gd = -np.divide(dphi, domega, out=np.zeros_like(dphi), where=np.abs(domega) > 1e-12)
    f_mid = (f[:-1] + f[1:]) / 2.0
    return f_mid, gd


def poles_zeros(filter_def: dict) -> tuple[np.ndarray, np.ndarray]:
    """Return zeros and poles of transfer function."""
    b = np.asarray(filter_def["b"], dtype=float)
    a = np.asarray(filter_def["a"], dtype=float)
    z = np.roots(b) if len(b) > 1 else np.array([])
    p = np.roots(a) if len(a) > 1 else np.array([])
    return z, p
