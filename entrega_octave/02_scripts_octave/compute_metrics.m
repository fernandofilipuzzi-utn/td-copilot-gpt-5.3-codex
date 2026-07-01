function metrics = compute_metrics(x_clean, x_noisy, y_fir, y_iir, fs, fir_order)
  % Compute quantitative metrics for FIR and IIR filtered outputs.
  delay_fir = round(fir_order / 2);

  y_fir_aligned = shift_left(y_fir, delay_fir);
  y_iir_aligned = y_iir;

  input_snr_db = snr_db(x_clean, x_noisy - x_clean);
  fir_snr_db = snr_db(x_clean, y_fir_aligned - x_clean);
  iir_snr_db = snr_db(x_clean, y_iir_aligned - x_clean);

  fir_rmse = rmse(x_clean, y_fir_aligned);
  iir_rmse = rmse(x_clean, y_iir_aligned);

  att_in_350_db = tone_level_db(x_noisy, fs, 350);
  att_fir_350_db = tone_level_db(y_fir_aligned, fs, 350);
  att_iir_350_db = tone_level_db(y_iir_aligned, fs, 350);

  metrics = struct();
  metrics.input_snr_db = input_snr_db;
  metrics.fir = struct("snr_db", fir_snr_db, "rmse", fir_rmse, "tone_350_db", att_fir_350_db);
  metrics.iir = struct("snr_db", iir_snr_db, "rmse", iir_rmse, "tone_350_db", att_iir_350_db);
  metrics.attenuation_350 = struct(
    "input_db", att_in_350_db,
    "fir_reduction_db", att_in_350_db - att_fir_350_db,
    "iir_reduction_db", att_in_350_db - att_iir_350_db
  );
endfunction

function y = shift_left(x, n)
  % Align FIR output: y_fir[D+m] ~ x[m], so trim first D samples and zero-pad tail.
  if n <= 0
    y = x;
    return;
  endif
  if n >= length(x)
    y = zeros(size(x));
    return;
  endif
  y = zeros(size(x));
  y(1:end-n) = x(n+1:end);
endfunction

function out = rmse(x, y)
  out = sqrt(mean((x - y).^2));
endfunction

function out = snr_db(signal, noise)
  out = 10 * log10((sum(signal.^2) + eps) / (sum(noise.^2) + eps));
endfunction

function level_db = tone_level_db(x, fs, tone_hz)
  n = length(x);
  nfft = 2^nextpow2(n);
  xw = x(:)' .* (0.54 - 0.46 * cos(2*pi*(0:n-1)/(n-1)));
  xfft = fft(xw, nfft);
  freqs = (0:nfft-1) * fs / nfft;

  [~, idx] = min(abs(freqs - tone_hz));
  mag = abs(xfft(idx));
  level_db = 20 * log10(mag + eps);
endfunction
