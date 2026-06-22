{ config, ... }:
{
  time = "2026-04-02T15:03:50+00:00";
  condition = config.programs.opencode.enable;
  message = ''
    OpenCode TUI configuration support has been added via the
    'programs.opencode.tui' option.
    Since OpenCode v1.2.15, TUI-specific settings like 'theme' and
    'keybinds' must be in a separate tui.json file instead of
    config.json.
    If you currently have 'theme', 'keybinds', or 'tui' in
    'programs.opencode.settings', you should move them to
    'programs.opencode.tui':
      programs.opencode.tui = {
        theme = "tokyonight";
        keybinds.leader = "alt+b";
      };

    For OpenCode v1.2.15+, theme, keybinds, and tui fields in the old location will be ignored.
    You must migrate to programs.opencode.tui for your settings to take effect.
    Home Manager will show a deprecation warning during rebuild.
    See https://opencode.ai/docs/config#tui for more information
  '';
}
