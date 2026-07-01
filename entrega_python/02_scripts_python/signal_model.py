"""Signal generation utilities for bearing condition monitoring."""

from __future__ import annotations

import numpy as np


def generate_time_vector(fs: float, duration_s: float) -> np.ndarray:
    """Create a uniform time vector."""
    n_samples = int(fs * duration_s)
    return np.arange(n_samples, dtype=float) / fs


def generate_components(
    t: np.ndarray,
    useful_freqs: tuple[float, float] = (30.0, 120.0),
    useful_amps: tuple[float, float] = (1.0, 0.7),
    interference_freq: float = 350.0,
    interference_amp: float = 0.8,
    noise_std: float = 0.25,
    rng_seed: int = 2026,
) -> dict[str, np.ndarray]:
    """Build synthetic signal components."""
    rng = np.random.default_rng(rng_seed)
    useful = useful_amps[0] * np.sin(2.0 * np.pi * useful_freqs[0] * t)
    useful += useful_amps[1] * np.sin(2.0 * np.pi * useful_freqs[1] * t)
    interference = interference_amp * np.sin(2.0 * np.pi * interference_freq * t)
    noise = rng.normal(0.0, noise_std, size=t.shape)
    x = useful + interference + noise
    return {
        "useful": useful,
        "interference": interference,
        "noise": noise,
        "input": x,
    }


def build_signal(fs: float = 1000.0, duration_s: float = 4.0) -> dict[str, np.ndarray | float]:
    """Generate complete dataset for the exam scenario."""
    t = generate_time_vector(fs=fs, duration_s=duration_s)
    parts = generate_components(t=t)
    parts["t"] = t
    parts["fs"] = fs
    return parts
