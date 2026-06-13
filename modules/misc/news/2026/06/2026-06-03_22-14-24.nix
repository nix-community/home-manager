{ config, ... }:
{
  time = "2026-06-03T14:14:24+00:00";
  condition = config.programs.prismlauncher.enable;
  message = ''
    `programs.prismlauncher` now supports managing Prism Launcher
    themes through {option}`programs.prismlauncher.themes`.

    Themes can be configured either as paths to complete theme directories, or
    as attribute sets used to generate `theme.json` and optionally
    `themeStyle.css`.
  '';
}
