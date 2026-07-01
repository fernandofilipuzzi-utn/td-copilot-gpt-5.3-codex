function [t, x_clean, x_noisy, meta] = generate_signal(params)
  % Generate synthetic vibration signal for condition monitoring.
  fs = params.fs;
  duration_s = params.duration_s;
  n = round(fs * duration_s);
  t = (0:n-1) ./ fs;

  rng(2026, "twister");

  useful_1 = 0.9 * sin(2 * pi * 30 * t);
  useful_2 = 0.6 * sin(2 * pi * 120 * t + pi/5);
  interference = 0.7 * sin(2 * pi * 350 * t + pi/9);
  noise = 0.20 * randn(size(t));

  x_clean = useful_1 + useful_2;
  x_noisy = x_clean + interference + noise;

  meta = struct();
  meta.fs = fs;
  meta.duration_s = duration_s;
  meta.useful_hz = [30, 120];
  meta.interference_hz = 350;
  meta.components = struct("useful_1", useful_1, "useful_2", useful_2, "interference", interference, "noise", noise);
endfunction
