function plot_results(t, x_clean, x_noisy, y_fir, y_iir, filters, fs, graphics_dir)
  % Generate and save required figures as PNG.
  if ~exist(graphics_dir, "dir")
    mkdir(graphics_dir);
  endif

  % Headless-friendly toolkit for terminal execution.
  try
    graphics_toolkit("gnuplot");
  catch
    % Fall back silently if gnuplot is unavailable.
  end_try_catch

  [f_fir, h_fir] = freq_response_from_ba(filters.fir.b, filters.fir.a, fs, 4096);
  [f_iir, h_iir] = freq_response_from_ba(filters.iir.b, filters.iir.a, fs, 4096);

  gd_fir = group_delay_from_h(h_fir, fs);
  gd_iir = group_delay_from_h(h_iir, fs);

  fig = figure("visible", "off");
  n_show = min(length(t), 2500);
  plot(t(1:n_show), x_noisy(1:n_show), "k", "linewidth", 1.0);
  hold on;
  plot(t(1:n_show), x_clean(1:n_show), "b", "linewidth", 1.2);
  plot(t(1:n_show), y_fir(1:n_show), "r", "linewidth", 1.1);
  plot(t(1:n_show), y_iir(1:n_show), "g", "linewidth", 1.1);
  hold off;
  grid on;
  xlabel("Time [s]");
  ylabel("Amplitude");
  title("Time Domain: Input and Filtered Signals");
  legend("Noisy input", "Clean reference", "FIR output", "IIR output", "location", "northeast");
  print(fig, fullfile(graphics_dir, "01_time_domain.png"), "-dpng", "-r150");
  close(fig);

  fig = figure("visible", "off");
  [f_x, m_x] = single_sided_spectrum(x_noisy, fs);
  [f_f, m_f] = single_sided_spectrum(y_fir, fs);
  [f_i, m_i] = single_sided_spectrum(y_iir, fs);
  plot(f_x, m_x, "k", "linewidth", 1.0);
  hold on;
  plot(f_f, m_f, "r", "linewidth", 1.0);
  plot(f_i, m_i, "g", "linewidth", 1.0);
  hold off;
  grid on;
  xlim([0, fs/2]);
  xlabel("Frequency [Hz]");
  ylabel("Magnitude [dB]");
  title("Single-Sided Spectrum");
  legend("Noisy input", "FIR output", "IIR output", "location", "northeast");
  print(fig, fullfile(graphics_dir, "02_spectrum.png"), "-dpng", "-r150");
  close(fig);

  fig = figure("visible", "off");
  subplot(2,1,1);
  plot(f_fir, 20*log10(abs(h_fir)+eps), "r", "linewidth", 1.2);
  grid on;
  xlabel("Frequency [Hz]");
  ylabel("Magnitude [dB]");
  title("FIR Frequency Response");
  subplot(2,1,2);
  plot(f_fir, unwrap(angle(h_fir)), "r", "linewidth", 1.1);
  grid on;
  xlabel("Frequency [Hz]");
  ylabel("Phase [rad]");
  print(fig, fullfile(graphics_dir, "03_fir_response.png"), "-dpng", "-r150");
  close(fig);

  fig = figure("visible", "off");
  subplot(2,1,1);
  plot(f_iir, 20*log10(abs(h_iir)+eps), "g", "linewidth", 1.2);
  grid on;
  xlabel("Frequency [Hz]");
  ylabel("Magnitude [dB]");
  title("IIR Frequency Response");
  subplot(2,1,2);
  plot(f_iir, unwrap(angle(h_iir)), "g", "linewidth", 1.1);
  grid on;
  xlabel("Frequency [Hz]");
  ylabel("Phase [rad]");
  print(fig, fullfile(graphics_dir, "04_iir_response.png"), "-dpng", "-r150");
  close(fig);

  fig = figure("visible", "off");
  imp_n = 400;
  imp = [1, zeros(1, imp_n-1)];
  h_fir_imp = filter(filters.fir.b, filters.fir.a, imp);
  h_iir_imp = filter(filters.iir.b, filters.iir.a, imp);
  subplot(2,1,1);
  stem(0:imp_n-1, h_fir_imp, "r", "filled");
  grid on;
  xlabel("n");
  ylabel("h[n]");
  title("FIR Impulse Response");
  subplot(2,1,2);
  stem(0:imp_n-1, h_iir_imp, "g", "filled");
  grid on;
  xlabel("n");
  ylabel("h[n]");
  title("IIR Impulse Response");
  print(fig, fullfile(graphics_dir, "05_impulse_responses.png"), "-dpng", "-r150");
  close(fig);

  fig = figure("visible", "off");
  plot(f_fir, gd_fir, "r", "linewidth", 1.2);
  hold on;
  plot(f_iir, gd_iir, "g", "linewidth", 1.2);
  hold off;
  grid on;
  xlim([0, fs/2]);
  xlabel("Frequency [Hz]");
  ylabel("Group Delay [samples]");
  title("Group Delay Comparison");
  legend("FIR", "IIR", "location", "northeast");
  print(fig, fullfile(graphics_dir, "06_group_delay.png"), "-dpng", "-r150");
  close(fig);

  fig = figure("visible", "off");
  z_iir = roots(filters.iir.b(:));
  p_iir = roots(filters.iir.a(:));
  th = linspace(0, 2*pi, 512);
  plot(cos(th), sin(th), "k--", "linewidth", 1.0);
  hold on;
  plot(real(z_iir), imag(z_iir), "ob", "markersize", 8, "linewidth", 1.3);
  plot(real(p_iir), imag(p_iir), "xr", "markersize", 8, "linewidth", 1.3);
  hold off;
  grid on;
  axis equal;
  xlabel("Real");
  ylabel("Imaginary");
  title("IIR Pole-Zero Map");
  legend("Unit circle", "Zeros", "Poles", "location", "southwest");
  print(fig, fullfile(graphics_dir, "07_iir_pole_zero.png"), "-dpng", "-r150");
  close(fig);
endfunction

function [f, h] = freq_response_from_ba(b, a, fs, nfft)
  w = linspace(0, pi, nfft/2 + 1);
  z = exp(1i * w);
  num = zeros(size(z));
  den = zeros(size(z));

  for k = 1:length(b)
    num = num + b(k) .* z.^(-(k-1));
  endfor

  for k = 1:length(a)
    den = den + a(k) .* z.^(-(k-1));
  endfor

  h = num ./ den;
  f = w .* fs / (2*pi);
endfunction

function gd = group_delay_from_h(h, fs)
  w = linspace(0, pi, length(h));
  ph = unwrap(angle(h));
  dph = diff(ph);
  dw = diff(w);
  gd_short = -dph ./ (dw + eps);
  gd = [gd_short, gd_short(end)];

  % Clip extreme numerical spikes for readability.
  gd = min(gd, fs);
  gd = max(gd, -fs);
endfunction

function [f, mag_db] = single_sided_spectrum(x, fs)
  n = length(x);
  nfft = 2^nextpow2(n);
  w = 0.54 - 0.46 * cos(2*pi*(0:n-1)/(n-1));
  xw = x(:)' .* w;
  xfft = fft(xw, nfft);

  xh = xfft(1:(nfft/2+1));
  mag = abs(xh);
  mag_db = 20 * log10(mag + eps);
  f = (0:(nfft/2)) * fs / nfft;
endfunction
