{ config, lib, ... }:
{
  programs.bash.enable = true;
  programs.zsh.enable = true;
  programs.fish.enable = true;
  programs.nushell = {
    enable = true;
    configDir = ".config/nushell";
  };
  xdg.enable = true;
  programs.vivid = {
    enable = true;
    package = lib.mkDefault null;
  };
  nmt.script =
    let
      command =
        if config.programs.vivid.package == null then "vivid" else lib.getExe config.programs.vivid.package;
      args = lib.escapeShellArgs (
        [ "generate" ]
        ++ lib.optional (config.programs.vivid.activeTheme != null) config.programs.vivid.activeTheme
      );
    in
    ''
      assertFileContains home-files/.bashrc 'export LS_COLORS="$(${command} ${args})"'
      assertFileContains home-files/.zshrc 'export LS_COLORS="$(${command} ${args})"'
      assertFileContains home-files/.config/fish/config.fish 'set -gx LS_COLORS "$(${command} ${args})"'
      assertFileContains home-files/.config/nushell/env.nu '$env.LS_COLORS = (${command} ${args})'
    '';
}
