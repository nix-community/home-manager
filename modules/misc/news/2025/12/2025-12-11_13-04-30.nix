{ config, ... }:

{
  time = "2025-12-11T19:04:30+00:00";
  condition =
    let
      helixEnabled = config.programs.helix.enable && config.programs.helix.defaultEditor;
      kakouneEnabled = config.programs.kakoune.enable && config.programs.kakoune.defaultEditor;
      neovimEnabled = config.programs.neovim.enable && config.programs.neovim.defaultEditor;
      vimEnabled = config.programs.vim.enable && config.programs.vim.defaultEditor;
      emacsEnabled = config.services.emacs.enable && config.services.emacs.defaultEditor;
    in
    helixEnabled || kakouneEnabled || neovimEnabled || vimEnabled || emacsEnabled;
  message = ''
    The 'defaultEditor' option now sets both {env}`EDITOR` and {env}`VISUAL`
    environment variables.

    Previously, only {env}`EDITOR` was set. The {env}`VISUAL` variable is now
    also configured to point to the same editor, which is the expected behavior
    for modern terminal editors.

    This change affects the following modules:
    - programs.helix
    - programs.kakoune
    - programs.neovim
    - programs.vim
    - services.emacs

    No action is required. This change should improve compatibility with tools
    that check {env}`VISUAL` before {env}`EDITOR`.
  '';
}
