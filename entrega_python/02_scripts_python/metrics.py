"""Metric calculations for filter comparison."""

from __future__ import annotations

import numpy as np


def snr_db(reference: np.ndarray, estimate: np.ndarray) -> float:
    """Compute SNR using reference as desired signal."""
    ref = np.asarray(reference, dtype=float)
    est = np.asarray(estimate, dtype=float)
    noise = est - ref
    p_sig = np.mean(ref**2)
    p_noise = np.mean(noise**2)
    if p_noise <= 1e-20:
        return 120.0
    return 10.0 * np.log10(p_sig / p_noise)


def rmse(reference: np.ndarray, estimate: np.ndarray) -> float:
    ref = np.asarray(reference, dtype=float)
    est = np.asarray(estimate, dtype=float)
    return float(np.sqrt(np.mean((ref - est) ** 2)))


def attenuation_db(freq: np.ndarray, h: np.ndarray, f_start: float) -> float:
    """Average attenuation above threshold frequency."""
    mask = freq >= f_start
    if not np.any(mask):
        return 0.0
    mag = np.abs(h[mask])
    mag = np.maximum(mag, 1e-12)
    return float(-20.0 * np.log10(np.mean(mag)))


def passband_ripple_db(freq: np.ndarray, h: np.ndarray, f1: float, f2: float) -> float:
    """Approximate passband ripple in dB."""
    mask = (freq >= f1) & (freq <= f2)
    if not np.any(mask):
        return 0.0
    mag_db = 20.0 * np.log10(np.maximum(np.abs(h[mask]), 1e-12))
    return float(np.max(mag_db) - np.min(mag_db))
