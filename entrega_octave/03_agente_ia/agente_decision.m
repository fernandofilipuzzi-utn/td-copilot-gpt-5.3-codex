function result = agente_decision(fs, ram_kb, mips, linear_phase_required, snr_in_db, max_latency_ms, steep_transition_required)
  % Rule-based agent for selecting FIR vs IIR in embedded filtering.
  if nargin < 7
    error("agente_decision requires 7 input arguments.");
  endif

  fir_score = 0;
  iir_score = 0;
  reasons = {};

  if linear_phase_required == 1
    fir_score = fir_score + 3;
    reasons{end+1} = "Linear phase required: FIR preferred.";
  else
    iir_score = iir_score + 1;
    reasons{end+1} = "Linear phase not mandatory: IIR acceptable.";
  endif

  if (ram_kb < 256) || (mips < 120)
    iir_score = iir_score + 3;
    reasons{end+1} = "Tight resources (RAM/MIPS): IIR preferred.";
  else
    fir_score = fir_score + 1;
    reasons{end+1} = "Enough resources for FIR convolution.";
  endif

  if max_latency_ms <= 5
    iir_score = iir_score + 2;
    reasons{end+1} = "Strict latency target: IIR preferred.";
  else
    fir_score = fir_score + 1;
    reasons{end+1} = "Latency budget allows FIR group delay.";
  endif

  if steep_transition_required == 1
    iir_score = iir_score + 2;
    reasons{end+1} = "Steep transition requested: IIR usually lower order.";
  else
    fir_score = fir_score + 1;
    reasons{end+1} = "Moderate transition: FIR still practical.";
  endif

  if snr_in_db < 5
    fir_score = fir_score + 1;
    reasons{end+1} = "Very noisy input: FIR linear phase can preserve waveform.";
  else
    iir_score = iir_score + 1;
    reasons{end+1} = "Input SNR acceptable: IIR distortions may be tolerable.";
  endif

  if fir_score >= iir_score
    recommendation = "FIR";
    structure = "Windowed-sinc band-pass, linear phase";
  else
    recommendation = "IIR";
    structure = "Cascaded biquad HP+LP (Butterworth-like)";
  endif

  result = struct();
  result.recommendation = recommendation;
  result.structure = structure;
  result.fir_score = fir_score;
  result.iir_score = iir_score;
  result.justification = reasons;
endfunction
