{ config, ... }:
{
  time = "2026-09-10T12:00:00+00:00";
  condition = config.programs.vivid.enable;
  message = ''
    Vivid shell integrations now generate LS_COLORS at build time when
    programs.vivid.package and programs.vivid.activeTheme are non-null.
    Shell startup reads the cached colors without running vivid.

    Configure custom themes and filetypes through programs.vivid.themes and
    programs.vivid.filetypes. Runtime changes to these files or VIVID_THEME
    no longer affect the cached colors. Generation remains at shell startup
    when package or activeTheme is null.
  '';
}
