{ config, ... }:
{
  time = "2026-08-31T18:55:53+00:00";
  condition =
    config.programs.vscode.enable
    || config.programs.vscodium.enable
    || config.programs.cursor.enable
    || config.programs.windsurf.enable
    || config.programs.kiro.enable
    || config.programs.antigravity.enable;
  message = ''
    The VS Code modules now support mutable user settings through these
    per-profile options:

    - `programs.vscode.profiles.<name>.mutableUserSettings`
    - `programs.vscodium.profiles.<name>.mutableUserSettings`
    - `programs.cursor.profiles.<name>.mutableUserSettings`
    - `programs.windsurf.profiles.<name>.mutableUserSettings`
    - `programs.kiro.profiles.<name>.mutableUserSettings`
    - `programs.antigravity.profiles.<name>.mutableUserSettings`

    When you enable one of these options, Home Manager merges settings from
    your configuration into the existing settings file during activation.
    Values from your configuration take precedence. The merge preserves other
    settings that you changed through the editor.

    Each option defaults to `false`.
  '';
}
