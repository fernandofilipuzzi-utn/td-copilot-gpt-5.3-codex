"""Plotting helpers with graceful fallback when matplotlib is unavailable."""

from __future__ import annotations

from pathlib import Path
import shutil
import subprocess
import tempfile

import numpy as np

try:
    import matplotlib.pyplot as plt  # type: ignore
    MPL_AVAILABLE = True
except Exception:
    plt = None
    MPL_AVAILABLE = False


def _save_csv_fallback(path: Path, x: np.ndarray, y: np.ndarray, header: str) -> None:
    data = np.column_stack([x, y])
    np.savetxt(path, data, delimiter=",", header=header, comments="")


def _gnuplot_escape(s: str) -> str:
    return s.replace("'", "''")


def _to_gnuplot_path(path: Path) -> str:
    return str(path).replace("\\", "/")


def _find_gnuplot_executable() -> str | None:
    direct = shutil.which("gnuplot")
    if direct:
        return direct

    candidates: list[Path] = []
    home = Path.home()
    octave_roots = [
        home / "AppData" / "Local" / "Programs" / "GNU Octave",
        Path("C:/Program Files/GNU Octave"),
        Path("C:/Program Files (x86)/GNU Octave"),
    ]

    for root in octave_roots:
        if not root.exists():
            continue
        candidates.extend(sorted(root.glob("Octave-*/mingw64/bin/gnuplot.exe"), reverse=True))
        candidates.extend(sorted(root.glob("Octave-*/mingw64/bin/pgnuplot.exe"), reverse=True))

    for cand in candidates:
        if cand.exists():
            return str(cand)
    return None


def _try_gnuplot_plot(
    x: np.ndarray,
    ys: list[np.ndarray],
    labels: list[str],
    title: str,
    xlabel: str,
    ylabel: str,
    out_png: Path,
    data_csv: Path,
) -> bool:
    gnuplot = _find_gnuplot_executable()
    if not gnuplot:
        return False

    data = np.column_stack([x] + ys)
    header = ",".join([xlabel] + labels)
    np.savetxt(data_csv, data, delimiter=",", header=header, comments="")

    out_png.parent.mkdir(parents=True, exist_ok=True)

    with tempfile.NamedTemporaryFile("w", suffix=".plt", delete=False, encoding="utf-8") as fp:
        script_path = Path(fp.name)
        fp.write("set datafile separator ','\n")
        fp.write("set terminal pngcairo size 1500,900\n")
        fp.write(f"set output '{_to_gnuplot_path(out_png)}'\n")
        fp.write("set grid\n")
        fp.write(f"set title '{_gnuplot_escape(title)}'\n")
        fp.write(f"set xlabel '{_gnuplot_escape(xlabel)}'\n")
        fp.write(f"set ylabel '{_gnuplot_escape(ylabel)}'\n")

        plots = []
        for idx, label in enumerate(labels, start=2):
            plots.append(
                f"'{_to_gnuplot_path(data_csv)}' using 1:{idx} with lines lw 1.4 title '{_gnuplot_escape(label)}'"
            )
        fp.write("plot " + ", ".join(plots) + "\n")

    try:
        proc = subprocess.run(
            [gnuplot, str(script_path)],
            capture_output=True,
            text=True,
            check=False,
        )
    finally:
        try:
            script_path.unlink(missing_ok=True)
        except Exception:
            pass

    if proc.returncode != 0:
        return False
    return out_png.exists() and out_png.stat().st_size > 0


def save_line_plot(
    x: np.ndarray,
    y: np.ndarray,
    title: str,
    xlabel: str,
    ylabel: str,
    out_png: Path,
    fallback_csv: Path,
) -> bool:
    if MPL_AVAILABLE:
        fig, ax = plt.subplots(figsize=(9, 4.5))
        ax.plot(x, y, linewidth=1.2)
        ax.set_title(title)
        ax.set_xlabel(xlabel)
        ax.set_ylabel(ylabel)
        ax.grid(True, alpha=0.3)
        fig.tight_layout()
        fig.savefig(out_png, dpi=130)
        plt.close(fig)
        return True

    if _try_gnuplot_plot(x, [y], [ylabel], title, xlabel, ylabel, out_png, fallback_csv):
        return True

    _save_csv_fallback(fallback_csv, x, y, f"{xlabel},{ylabel}")
    return False


def save_multi_line_plot(
    x: np.ndarray,
    ys: list[np.ndarray],
    labels: list[str],
    title: str,
    xlabel: str,
    ylabel: str,
    out_png: Path,
    fallback_csv: Path,
) -> bool:
    if MPL_AVAILABLE:
        fig, ax = plt.subplots(figsize=(9, 4.5))
        for y, label in zip(ys, labels):
            ax.plot(x, y, linewidth=1.2, label=label)
        ax.set_title(title)
        ax.set_xlabel(xlabel)
        ax.set_ylabel(ylabel)
        ax.grid(True, alpha=0.3)
        ax.legend()
        fig.tight_layout()
        fig.savefig(out_png, dpi=130)
        plt.close(fig)
        return True

    if _try_gnuplot_plot(x, ys, labels, title, xlabel, ylabel, out_png, fallback_csv):
        return True

    data = np.column_stack([x] + ys)
    header = ",".join([xlabel] + labels)
    np.savetxt(fallback_csv, data, delimiter=",", header=header, comments="")
    return False
