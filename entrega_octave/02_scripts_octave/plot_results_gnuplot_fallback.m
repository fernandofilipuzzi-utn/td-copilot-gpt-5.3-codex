function ok = plot_results_gnuplot_fallback(t, x_clean, x_noisy, y_fir, y_iir, filters, fs, graphics_dir)
  % Generate required PNG plots through external gnuplot (headless-safe).
  ok = false;

  if ~exist(graphics_dir, "dir")
    mkdir(graphics_dir);
  endif

  if system("gnuplot --version > NUL 2>&1") ~= 0
    error("gnuplot executable not found in PATH during fallback rendering.");
  endif

  tmp_dir = fullfile(graphics_dir, "_gnuplot_tmp");
  if ~exist(tmp_dir, "dir")
    mkdir(tmp_dir);
  endif

  % -------- Data preparation --------
  n_show = min(length(t), 2500);
  d_time = [t(1:n_show)', x_noisy(1:n_show)', x_clean(1:n_show)', y_fir(1:n_show)', y_iir(1:n_show)'];
  write_matrix(fullfile(tmp_dir, "time.dat"), d_time);

  [f_x, m_x] = single_sided_spectrum_local(x_noisy, fs);
  [f_f, m_f] = single_sided_spectrum_local(y_fir, fs);
  [f_i, m_i] = single_sided_spectrum_local(y_iir, fs);
  d_spec = [f_x', m_x', m_f', m_i'];
  write_matrix(fullfile(tmp_dir, "spectrum.dat"), d_spec);

  [f_fir, h_fir] = freq_response_from_ba_local(filters.fir.b, filters.fir.a, fs, 4096);
  [f_iir, h_iir] = freq_response_from_ba_local(filters.iir.b, filters.iir.a, fs, 4096);

  d_fir_resp = [f_fir', (20*log10(abs(h_fir) + eps))', unwrap(angle(h_fir))'];
  d_iir_resp = [f_iir', (20*log10(abs(h_iir) + eps))', unwrap(angle(h_iir))'];
  write_matrix(fullfile(tmp_dir, "fir_resp.dat"), d_fir_resp);
  write_matrix(fullfile(tmp_dir, "iir_resp.dat"), d_iir_resp);

  imp_n = 400;
  imp = [1, zeros(1, imp_n - 1)];
  h_fir_imp = filter(filters.fir.b, filters.fir.a, imp);
  h_iir_imp = filter(filters.iir.b, filters.iir.a, imp);
  d_imp = [(0:imp_n-1)', h_fir_imp', h_iir_imp'];
  write_matrix(fullfile(tmp_dir, "impulse.dat"), d_imp);

  gd_fir = group_delay_from_h_local(h_fir, fs);
  gd_iir = group_delay_from_h_local(h_iir, fs);
  d_gd = [f_fir', gd_fir', gd_iir'];
  write_matrix(fullfile(tmp_dir, "group_delay.dat"), d_gd);

  z_iir = roots(filters.iir.b(:));
  p_iir = roots(filters.iir.a(:));
  th = linspace(0, 2*pi, 512);
  d_unit = [cos(th(:)), sin(th(:))];
  d_zeros = [real(z_iir(:)), imag(z_iir(:))];
  d_poles = [real(p_iir(:)), imag(p_iir(:))];
  write_matrix(fullfile(tmp_dir, "unit_circle.dat"), d_unit);
  write_matrix(fullfile(tmp_dir, "zeros.dat"), d_zeros);
  write_matrix(fullfile(tmp_dir, "poles.dat"), d_poles);

  % -------- Plot scripts --------
  run_gnuplot(fullfile(tmp_dir, "01_time_domain.plt"), {
    "set terminal pngcairo size 1500,900", ...
    sprintf("set output '%s'", to_gnuplot_path(fullfile(graphics_dir, "01_time_domain.png"))), ...
    "set grid", ...
    "set title 'Time Domain: Input and Filtered Signals'", ...
    "set xlabel 'Time [s]'", ...
    "set ylabel 'Amplitude'", ...
    sprintf("plot '%s' using 1:2 with lines lw 1.3 title 'Noisy input', '%s' using 1:3 with lines lw 1.6 title 'Clean reference', '%s' using 1:4 with lines lw 1.4 title 'FIR output', '%s' using 1:5 with lines lw 1.4 title 'IIR output'", to_gnuplot_path(fullfile(tmp_dir, "time.dat")), to_gnuplot_path(fullfile(tmp_dir, "time.dat")), to_gnuplot_path(fullfile(tmp_dir, "time.dat")), to_gnuplot_path(fullfile(tmp_dir, "time.dat")))
  });

  run_gnuplot(fullfile(tmp_dir, "02_spectrum.plt"), {
    "set terminal pngcairo size 1500,900", ...
    sprintf("set output '%s'", to_gnuplot_path(fullfile(graphics_dir, "02_spectrum.png"))), ...
    "set grid", ...
    "set title 'Single-Sided Spectrum'", ...
    "set xlabel 'Frequency [Hz]'", ...
    "set ylabel 'Magnitude [dB]'", ...
    sprintf("plot '%s' using 1:2 with lines lw 1.2 title 'Noisy input', '%s' using 1:3 with lines lw 1.3 title 'FIR output', '%s' using 1:4 with lines lw 1.3 title 'IIR output'", to_gnuplot_path(fullfile(tmp_dir, "spectrum.dat")), to_gnuplot_path(fullfile(tmp_dir, "spectrum.dat")), to_gnuplot_path(fullfile(tmp_dir, "spectrum.dat")))
  });

  run_gnuplot(fullfile(tmp_dir, "03_fir_response.plt"), {
    "set terminal pngcairo size 1500,1000", ...
    sprintf("set output '%s'", to_gnuplot_path(fullfile(graphics_dir, "03_fir_response.png"))), ...
    "set multiplot layout 2,1 title 'FIR Frequency Response'", ...
    "set grid", ...
    "set xlabel 'Frequency [Hz]'", ...
    "set ylabel 'Magnitude [dB]'", ...
    sprintf("plot '%s' using 1:2 with lines lw 1.5 title 'Magnitude'", to_gnuplot_path(fullfile(tmp_dir, "fir_resp.dat"))), ...
    "set xlabel 'Frequency [Hz]'", ...
    "set ylabel 'Phase [rad]'", ...
    sprintf("plot '%s' using 1:3 with lines lw 1.5 title 'Phase'", to_gnuplot_path(fullfile(tmp_dir, "fir_resp.dat"))), ...
    "unset multiplot"
  });

  run_gnuplot(fullfile(tmp_dir, "04_iir_response.plt"), {
    "set terminal pngcairo size 1500,1000", ...
    sprintf("set output '%s'", to_gnuplot_path(fullfile(graphics_dir, "04_iir_response.png"))), ...
    "set multiplot layout 2,1 title 'IIR Frequency Response'", ...
    "set grid", ...
    "set xlabel 'Frequency [Hz]'", ...
    "set ylabel 'Magnitude [dB]'", ...
    sprintf("plot '%s' using 1:2 with lines lw 1.5 title 'Magnitude'", to_gnuplot_path(fullfile(tmp_dir, "iir_resp.dat"))), ...
    "set xlabel 'Frequency [Hz]'", ...
    "set ylabel 'Phase [rad]'", ...
    sprintf("plot '%s' using 1:3 with lines lw 1.5 title 'Phase'", to_gnuplot_path(fullfile(tmp_dir, "iir_resp.dat"))), ...
    "unset multiplot"
  });

  run_gnuplot(fullfile(tmp_dir, "05_impulse.plt"), {
    "set terminal pngcairo size 1500,1000", ...
    sprintf("set output '%s'", to_gnuplot_path(fullfile(graphics_dir, "05_impulse_responses.png"))), ...
    "set multiplot layout 2,1 title 'Impulse Responses'", ...
    "set grid", ...
    "set xlabel 'n'", ...
    "set ylabel 'h[n]'", ...
    sprintf("plot '%s' using 1:2 with lines lw 1.2 title 'FIR h[n]'", to_gnuplot_path(fullfile(tmp_dir, "impulse.dat"))), ...
    "set xlabel 'n'", ...
    "set ylabel 'h[n]'", ...
    sprintf("plot '%s' using 1:3 with lines lw 1.2 title 'IIR h[n]'", to_gnuplot_path(fullfile(tmp_dir, "impulse.dat"))), ...
    "unset multiplot"
  });

  run_gnuplot(fullfile(tmp_dir, "06_group_delay.plt"), {
    "set terminal pngcairo size 1500,900", ...
    sprintf("set output '%s'", to_gnuplot_path(fullfile(graphics_dir, "06_group_delay.png"))), ...
    "set grid", ...
    "set title 'Group Delay Comparison'", ...
    "set xlabel 'Frequency [Hz]'", ...
    "set ylabel 'Group Delay [samples]'", ...
    sprintf("plot '%s' using 1:2 with lines lw 1.4 title 'FIR', '%s' using 1:3 with lines lw 1.4 title 'IIR'", to_gnuplot_path(fullfile(tmp_dir, "group_delay.dat")), to_gnuplot_path(fullfile(tmp_dir, "group_delay.dat")))
  });

  run_gnuplot(fullfile(tmp_dir, "07_pz.plt"), {
    "set terminal pngcairo size 1200,1200", ...
    sprintf("set output '%s'", to_gnuplot_path(fullfile(graphics_dir, "07_iir_pole_zero.png"))), ...
    "set title 'IIR Pole-Zero Map'", ...
    "set grid", ...
    "set size ratio -1", ...
    "set xlabel 'Real'", ...
    "set ylabel 'Imaginary'", ...
    sprintf("plot '%s' using 1:2 with lines lw 1.0 title 'Unit circle', '%s' using 1:2 with points pt 7 ps 1.3 lc rgb 'blue' title 'Zeros', '%s' using 1:2 with points pt 2 ps 1.4 lc rgb 'red' title 'Poles'", to_gnuplot_path(fullfile(tmp_dir, "unit_circle.dat")), to_gnuplot_path(fullfile(tmp_dir, "zeros.dat")), to_gnuplot_path(fullfile(tmp_dir, "poles.dat")))
  });

  % Validate required outputs.
  expected = {
    fullfile(graphics_dir, "01_time_domain.png"),
    fullfile(graphics_dir, "02_spectrum.png"),
    fullfile(graphics_dir, "03_fir_response.png"),
    fullfile(graphics_dir, "04_iir_response.png"),
    fullfile(graphics_dir, "05_impulse_responses.png"),
    fullfile(graphics_dir, "06_group_delay.png"),
    fullfile(graphics_dir, "07_iir_pole_zero.png")
  };

  ok = true;
  for i = 1:numel(expected)
    if ~exist(expected{i}, "file")
      ok = false;
      break;
    endif
  endfor

  if ok
    if exist(fullfile(graphics_dir, "README_FALTANTES.md"), "file")
      unlink(fullfile(graphics_dir, "README_FALTANTES.md"));
    endif
    if exist(tmp_dir, "dir")
      rmdir(tmp_dir, "s");
    endif
  endif
endfunction

function run_gnuplot(script_path, lines)
  fid = fopen(script_path, "w");
  if fid < 0
    error("Could not write gnuplot script: %s", script_path);
  endif
  for i = 1:numel(lines)
    fprintf(fid, "%s\n", lines{i});
  endfor
  fclose(fid);

  cmd = sprintf('gnuplot "%s"', script_path);
  status = system(cmd);
  if status ~= 0
    error("gnuplot command failed for script: %s", script_path);
  endif
endfunction

function write_matrix(path, m)
  dlmwrite(path, m, "delimiter", " ", "precision", 10);
endfunction

function p = to_gnuplot_path(path)
  p = strrep(path, "\\", "/");
endfunction

function [f, h] = freq_response_from_ba_local(b, a, fs, nfft)
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

function gd = group_delay_from_h_local(h, fs)
  w = linspace(0, pi, length(h));
  ph = unwrap(angle(h));
  dph = diff(ph);
  dw = diff(w);
  gd_short = -dph ./ (dw + eps);
  gd = [gd_short, gd_short(end)];
  gd = min(gd, fs);
  gd = max(gd, -fs);
endfunction

function [f, mag_db] = single_sided_spectrum_local(x, fs)
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
