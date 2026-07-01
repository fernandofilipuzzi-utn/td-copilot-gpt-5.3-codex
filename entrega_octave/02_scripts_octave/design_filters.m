function filters = design_filters(fs)
  % Design one FIR and one IIR band-pass filter without external toolboxes.
  f1 = 10;
  f2 = 200;

  fir_order = 300; % 301 taps, linear phase (ensures 30 Hz in flat passband)
  b_fir = fir_bandpass_windowed(fs, f1, f2, fir_order);
  a_fir = 1;

  q_bw = 1 / sqrt(2); % Butterworth-like biquad Q
  [b_hp, a_hp] = biquad_highpass(f1, fs, q_bw);
  [b_lp, a_lp] = biquad_lowpass(f2, fs, q_bw);

  b_iir = conv(b_hp, b_lp);
  a_iir = conv(a_hp, a_lp);

  filters = struct();
  filters.fir = struct("b", b_fir, "a", a_fir, "order", fir_order, "type", "FIR band-pass (windowed sinc)");
  filters.iir = struct("b", b_iir, "a", a_iir, "order", length(a_iir)-1, "type", "IIR band-pass (HP biquad + LP biquad)");
  filters.spec = struct("fs", fs, "passband_hz", [f1, f2], "stopband_hz", [0, 8; 280, fs/2], "rp_db", 1, "as_db", 40);
endfunction

function h = fir_bandpass_windowed(fs, f1, f2, order)
  n = 0:order;
  m = n - order/2;

  h_lp2 = 2 * (f2/fs) .* sinc(2 * (f2/fs) .* m);
  h_lp1 = 2 * (f1/fs) .* sinc(2 * (f1/fs) .* m);
  h_ideal = h_lp2 - h_lp1;

  w = 0.54 - 0.46 * cos(2 * pi * n / order);
  h = h_ideal .* w;

  % Normalize gain around band center.
  f0 = (f1 + f2) / 2;
  gain = abs(eval_freq_response(h, 1, 2*pi*f0/fs));
  if gain > 0
    h = h ./ gain;
  endif
endfunction

function [b, a] = biquad_lowpass(fc, fs, q)
  w0 = 2 * pi * fc / fs;
  alpha = sin(w0) / (2 * q);
  cosw0 = cos(w0);

  b0 = (1 - cosw0) / 2;
  b1 = 1 - cosw0;
  b2 = (1 - cosw0) / 2;
  a0 = 1 + alpha;
  a1 = -2 * cosw0;
  a2 = 1 - alpha;

  b = [b0, b1, b2] ./ a0;
  a = [1, a1/a0, a2/a0];
endfunction

function [b, a] = biquad_highpass(fc, fs, q)
  w0 = 2 * pi * fc / fs;
  alpha = sin(w0) / (2 * q);
  cosw0 = cos(w0);

  b0 = (1 + cosw0) / 2;
  b1 = -(1 + cosw0);
  b2 = (1 + cosw0) / 2;
  a0 = 1 + alpha;
  a1 = -2 * cosw0;
  a2 = 1 - alpha;

  b = [b0, b1, b2] ./ a0;
  a = [1, a1/a0, a2/a0];
endfunction

function h = eval_freq_response(b, a, w)
  z = exp(1i * w);
  num = 0;
  den = 0;

  for k = 1:length(b)
    num = num + b(k) * z^(-(k-1));
  endfor

  for k = 1:length(a)
    den = den + a(k) * z^(-(k-1));
  endfor

  h = num / den;
endfunction
