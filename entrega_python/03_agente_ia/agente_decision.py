"""Rule-based agent for FIR/IIR recommendation."""

from __future__ import annotations

import csv
from pathlib import Path


def recommend_filter(
    fs: float,
    ram_kb: float,
    mips: float,
    linear_phase_required: bool,
    snr_in_db: float,
    latency_ms: float,
    steep_slope_required: bool,
) -> dict[str, str]:
    rules_triggered = []

    if linear_phase_required:
        rules_triggered.append("R1: Linear phase required -> favor FIR.")
    if ram_kb < 64 or mips < 80:
        rules_triggered.append("R2: Tight resources -> favor IIR.")
    if latency_ms < 3.0:
        rules_triggered.append("R3: Very low latency target -> favor IIR.")
    if steep_slope_required and ram_kb >= 128 and mips >= 120:
        rules_triggered.append("R4: High slope and enough resources -> FIR possible.")
    if snr_in_db < 5.0:
        rules_triggered.append("R5: Very noisy input -> prioritize robust attenuation.")

    score_fir = 0
    score_iir = 0

    for r in rules_triggered:
        if "favor FIR" in r or "FIR possible" in r:
            score_fir += 1
        if "favor IIR" in r:
            score_iir += 1

    if snr_in_db < 5.0 and not linear_phase_required:
        score_iir += 1

    if score_fir >= score_iir:
        recommendation = "FIR"
        structure = "Direct form FIR, symmetric coefficients"
        reason = "Selected for linear phase and predictable delay."
    else:
        recommendation = "IIR"
        structure = "Cascade biquad IIR (SOS), float32"
        reason = "Selected for low computational and memory cost."

    return {
        "recommendation": recommendation,
        "structure": structure,
        "reason": reason,
        "rules": " | ".join(rules_triggered) if rules_triggered else "No specific constraints triggered.",
    }


def run_scenarios(csv_path: Path, out_md: Path) -> None:
    rows = []
    with csv_path.open("r", encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            result = recommend_filter(
                fs=float(row["fs"]),
                ram_kb=float(row["ram_kb"]),
                mips=float(row["mips"]),
                linear_phase_required=row["linear_phase_required"].strip().lower() == "true",
                snr_in_db=float(row["snr_in_db"]),
                latency_ms=float(row["latency_ms"]),
                steep_slope_required=row["steep_slope_required"].strip().lower() == "true",
            )
            rows.append((row["scenario"], result))

    lines = []
    lines.append("# Resultados del agente de decision\n\n")
    lines.append("| Escenario | Recomendacion | Estructura sugerida | Razon | Reglas activadas |\n")
    lines.append("|---|---|---|---|---|\n")
    for scenario, result in rows:
        lines.append(
            f"| {scenario} | {result['recommendation']} | {result['structure']} | {result['reason']} | {result['rules']} |\n"
        )

    out_md.write_text("".join(lines), encoding="utf-8")


if __name__ == "__main__":
    base = Path(__file__).resolve().parent
    run_scenarios(base / "escenarios_prueba.csv", base / "resultados_agente.md")
    print("Agent scenarios executed.")
