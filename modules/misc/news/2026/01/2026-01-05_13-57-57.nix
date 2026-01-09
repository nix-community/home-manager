{ pkgs, ... }:

{
  time = "2026-01-05T11:57:57+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    A new module is available: 'programs.workstyle'.

    Workstyle dynamically renames Sway/i3/Hyprland workspaces to indicate
    which programs are running in each one. For example, with a font icon.
  '';
}
