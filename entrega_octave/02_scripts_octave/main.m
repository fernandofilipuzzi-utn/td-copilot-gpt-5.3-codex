function main()
  close all;
  clc;

  this_dir = fileparts(mfilename("fullpath"));
  root_dir = fileparts(this_dir);
  graphics_dir = fullfile(root_dir, "05_graficos");
  agent_dir = fullfile(root_dir, "03_agente_ia");
  report_dir = fullfile(root_dir, "01_informe");

  addpath(this_dir);
  addpath(agent_dir);

  if ~exist(graphics_dir, "dir")
    mkdir(graphics_dir);
  endif

  params = struct();
  params.fs = 1000;
  params.duration_s = 6;

  [t, x_clean, x_noisy, meta] = generate_signal(params);
  filters = design_filters(params.fs);

  y_fir = filter(filters.fir.b, filters.fir.a, x_noisy);
  y_iir = filter(filters.iir.b, filters.iir.a, x_noisy);

  metrics = compute_metrics(x_clean, x_noisy, y_fir, y_iir, params.fs, filters.fir.order);
  plot_ok = true;
  plot_mode = "native";
  plot_err = "";
  try
    plot_results(t, x_clean, x_noisy, y_fir, y_iir, filters, params.fs, graphics_dir);
  catch err
    % Try external gnuplot fallback if native backend fails.
    try
      fallback_ok = plot_results_gnuplot_fallback(t, x_clean, x_noisy, y_fir, y_iir, filters, params.fs, graphics_dir);
      if fallback_ok
        plot_ok = true;
        plot_mode = "gnuplot_fallback";
        plot_err = sprintf("Native backend failed: %s", err.message);
      else
        plot_ok = false;
        plot_mode = "none";
        plot_err = sprintf("Native backend failed and fallback returned no plots. Native error: %s", err.message);
      endif
    catch err2
      plot_ok = false;
      plot_mode = "none";
      plot_err = sprintf("Native error: %s | Fallback error: %s", err.message, err2.message);
    end_try_catch

    if ~plot_ok
      fallback_path = fullfile(graphics_dir, "README_FALTANTES.md");
      fid_fallback = fopen(fallback_path, "w");
      if fid_fallback >= 0
        fprintf(fid_fallback, "# Graficos pendientes de generacion\n\n");
        fprintf(fid_fallback, "La ejecucion en este entorno no pudo renderizar PNG en modo headless.\n\n");
        fprintf(fid_fallback, "Motivo: %s\n\n", plot_err);
        fprintf(fid_fallback, "Cuando exista un backend grafico compatible, reejecutar:\n\n");
        fprintf(fid_fallback, "octave --eval \"addpath('entrega_octave/02_scripts_octave'); main\"\n");
        fclose(fid_fallback);
      endif
    endif
  end_try_catch

  agent_results = run_agent_validation(fullfile(agent_dir, "escenarios_prueba.csv"));
  write_agent_results_md(fullfile(agent_dir, "resultados_agente.md"), agent_results);

  write_table_md(fullfile(report_dir, "tabla_comparativa_fir_iir.md"), metrics, filters, meta);
  write_run_log(fullfile(this_dir, "run_log.md"), metrics, filters, agent_results, graphics_dir, plot_ok, plot_err, plot_mode);

  fprintf("Execution finished. Artifacts generated in %s\n", root_dir);
endfunction

function rows = run_agent_validation(csv_path)
  rows = parse_scenarios_csv(csv_path);
  for i = 1:length(rows)
    r = rows(i);
    result = agente_decision(r.fs, r.ram_kb, r.mips, r.linear_phase_required, r.snr_in_db, r.max_latency_ms, r.steep_transition_required);
    rows(i).prediction = result.recommendation;
    rows(i).fir_score = result.fir_score;
    rows(i).iir_score = result.iir_score;
    rows(i).justification = strjoin(result.justification, " ");
    rows(i).is_match = strcmpi(strtrim(rows(i).expected), strtrim(result.recommendation));
  endfor
endfunction

function rows = parse_scenarios_csv(csv_path)
  fid = fopen(csv_path, "r");
  if fid < 0
    error("Could not open scenarios file: %s", csv_path);
  endif

  header = fgetl(fid); %#ok<NASGU>
  c = textscan(fid, "%s %f %f %f %f %f %f %f %s", "Delimiter", ",");
  fclose(fid);

  n = length(c{1});
  rows = repmat(struct(
    "id", "",
    "fs", 0,
    "ram_kb", 0,
    "mips", 0,
    "linear_phase_required", 0,
    "snr_in_db", 0,
    "max_latency_ms", 0,
    "steep_transition_required", 0,
    "expected", "",
    "prediction", "",
    "fir_score", 0,
    "iir_score", 0,
    "justification", "",
    "is_match", false
  ), 1, n);

  for i = 1:n
    rows(i).id = c{1}{i};
    rows(i).fs = c{2}(i);
    rows(i).ram_kb = c{3}(i);
    rows(i).mips = c{4}(i);
    rows(i).linear_phase_required = c{5}(i);
    rows(i).snr_in_db = c{6}(i);
    rows(i).max_latency_ms = c{7}(i);
    rows(i).steep_transition_required = c{8}(i);
    rows(i).expected = c{9}{i};
  endfor
endfunction

function write_agent_results_md(path_md, rows)
  fid = fopen(path_md, "w");
  if fid < 0
    error("Could not write file: %s", path_md);
  endif

  matches = [rows.is_match];
  acc = 100 * sum(matches) / max(1, length(matches));

  fprintf(fid, "# Resultados del Agente de Decision\n\n");
  fprintf(fid, "Validacion automatica de escenarios en Octave.\n\n");
  fprintf(fid, "- Escenarios evaluados: %d\n", length(rows));
  fprintf(fid, "- Exactitud respecto a expectativa: %.2f%%\n\n", acc);

  fprintf(fid, "| ID | Esperado | Predicho | FIR score | IIR score | Match |\n");
  fprintf(fid, "|---|---|---|---:|---:|---|\n");
  for i = 1:length(rows)
    mark = "NO";
    if rows(i).is_match
      mark = "SI";
    endif
    fprintf(fid, "| %s | %s | %s | %d | %d | %s |\n", rows(i).id, rows(i).expected, rows(i).prediction, rows(i).fir_score, rows(i).iir_score, mark);
  endfor

  fprintf(fid, "\n## Justificaciones\n\n");
  for i = 1:length(rows)
    fprintf(fid, "- **%s**: %s\n", rows(i).id, rows(i).justification);
  endfor

  fclose(fid);
endfunction

function write_table_md(path_md, metrics, filters, meta)
  fid = fopen(path_md, "w");
  if fid < 0
    error("Could not write file: %s", path_md);
  endif

  fprintf(fid, "# Tabla Comparativa FIR vs IIR\n\n");
  fprintf(fid, "Contexto: opcion de monitoreo de rodamientos, fs=%d Hz, componentes utiles en 30/120 Hz e interferencia en %d Hz.\n\n", meta.fs, meta.interference_hz);
  fprintf(fid, "| Criterio | FIR | IIR |\n");
  fprintf(fid, "|---|---:|---:|\n");
  fprintf(fid, "| Tipo | %s | %s |\n", filters.fir.type, filters.iir.type);
  fprintf(fid, "| Orden aproximado | %d | %d |\n", filters.fir.order, filters.iir.order);
  fprintf(fid, "| SNR salida [dB] | %.4f | %.4f |\n", metrics.fir.snr_db, metrics.iir.snr_db);
  fprintf(fid, "| RMSE vs referencia limpia | %.6f | %.6f |\n", metrics.fir.rmse, metrics.iir.rmse);
  fprintf(fid, "| Reduccion tono 350 Hz [dB] | %.4f | %.4f |\n", metrics.attenuation_350.fir_reduction_db, metrics.attenuation_350.iir_reduction_db);
  fprintf(fid, "| Fase lineal | SI | NO (aprox) |\n");
  fprintf(fid, "| Costo computacional | Alto | Medio/Bajo |\n\n");

  fprintf(fid, "## Observaciones\n\n");
  fprintf(fid, "- FIR prioriza fidelidad temporal por fase casi lineal.\n");
  fprintf(fid, "- IIR ofrece menor orden efectivo con respuesta mas compacta.\n");
  fprintf(fid, "- La recomendacion final depende de restricciones embebidas (latencia y RAM).\n");

  fclose(fid);
endfunction

function write_run_log(path_md, metrics, filters, agent_rows, graphics_dir, plot_ok, plot_err, plot_mode)
  fid = fopen(path_md, "w");
  if fid < 0
    error("Could not write file: %s", path_md);
  endif

  timestamp = strftime("%Y-%m-%d %H:%M:%S", localtime(time()));
  matches = [agent_rows.is_match];
  acc = 100 * sum(matches) / max(1, length(matches));

  fprintf(fid, "# Run Log - Octave\n\n");
  fprintf(fid, "- Fecha ejecucion: %s\n", timestamp);
  if strcmp(plot_mode, "native")
    fprintf(fid, "- Estado: SUCCESS\n\n");
  elseif strcmp(plot_mode, "gnuplot_fallback")
    fprintf(fid, "- Estado: SUCCESS_WITH_GNUPLOT_FALLBACK\n\n");
  else
    fprintf(fid, "- Estado: SUCCESS_WITHOUT_PLOTS\n\n");
  endif

  fprintf(fid, "## Parametros\n\n");
  fprintf(fid, "- fs: 1000 Hz\n");
  fprintf(fid, "- Banda util objetivo: 10-200 Hz\n");
  fprintf(fid, "- Interferencia sintetica: 350 Hz\n");
  fprintf(fid, "- FIR order: %d\n", filters.fir.order);
  fprintf(fid, "- IIR order: %d\n\n", filters.iir.order);

  fprintf(fid, "## Metricas\n\n");
  fprintf(fid, "- SNR entrada: %.4f dB\n", metrics.input_snr_db);
  fprintf(fid, "- FIR SNR salida: %.4f dB\n", metrics.fir.snr_db);
  fprintf(fid, "- IIR SNR salida: %.4f dB\n", metrics.iir.snr_db);
  fprintf(fid, "- FIR RMSE: %.6f\n", metrics.fir.rmse);
  fprintf(fid, "- IIR RMSE: %.6f\n", metrics.iir.rmse);
  fprintf(fid, "- Reduccion 350 Hz FIR: %.4f dB\n", metrics.attenuation_350.fir_reduction_db);
  fprintf(fid, "- Reduccion 350 Hz IIR: %.4f dB\n\n", metrics.attenuation_350.iir_reduction_db);

  fprintf(fid, "## Agente de decision\n\n");
  fprintf(fid, "- Escenarios evaluados: %d\n", length(agent_rows));
  fprintf(fid, "- Exactitud vs esperado: %.2f%%\n\n", acc);

  fprintf(fid, "## Graficos\n\n");
  if plot_ok
    fprintf(fid, "- %s/01_time_domain.png\n", graphics_dir);
    fprintf(fid, "- %s/02_spectrum.png\n", graphics_dir);
    fprintf(fid, "- %s/03_fir_response.png\n", graphics_dir);
    fprintf(fid, "- %s/04_iir_response.png\n", graphics_dir);
    fprintf(fid, "- %s/05_impulse_responses.png\n", graphics_dir);
    fprintf(fid, "- %s/06_group_delay.png\n", graphics_dir);
    fprintf(fid, "- %s/07_iir_pole_zero.png\n", graphics_dir);
    if strcmp(plot_mode, "gnuplot_fallback")
      fprintf(fid, "- Metodo de render: fallback externo con gnuplot.\n");
      fprintf(fid, "- Nota: %s\n", plot_err);
    endif
  else
    fprintf(fid, "- No se generaron PNG por limitacion del backend grafico.\n");
    fprintf(fid, "- Error capturado: %s\n", plot_err);
    fprintf(fid, "- Ver nota: %s/README_FALTANTES.md\n", graphics_dir);
  endif

  fclose(fid);
endfunction
