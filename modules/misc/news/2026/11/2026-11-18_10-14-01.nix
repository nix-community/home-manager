{ config, ... }: {
  time = "2026-11-18T04:44:01+00:00";
  condition = config.programs.stylua.enable && config.programs.stylua.settings != { };
  message = ''
    `programs.stylua` no longer wraps the binary with `--search-parent-directories`.
    Many formatters pass that flag to stylua by default (for example, conform.nvim passes this
    flag to stylua by default).
  '';
}
