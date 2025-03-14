{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.autojump;
  package = pkgs.autojump;

in {
  meta.maintainers = [ maintainers.evanjs ];

  options.programs.autojump = {
    enable = mkEnableOption "autojump";

    enableBashIntegration =
      lib.hm.shell.mkBashIntegrationOption { inherit config; };

    enableFishIntegration =
      lib.hm.shell.mkFishIntegrationOption { inherit config; };

    enableZshIntegration =
      lib.hm.shell.mkZshIntegrationOption { inherit config; };
  };

  config = mkIf cfg.enable {
    home.packages = [ package ];

    programs.bash.initExtra = mkIf cfg.enableBashIntegration (mkBefore ''
      . ${package}/share/autojump/autojump.bash
    '');

    programs.zsh.initExtra = mkIf cfg.enableZshIntegration ''
      . ${package}/share/autojump/autojump.zsh
    '';

    programs.fish.interactiveShellInit = mkIf cfg.enableFishIntegration ''
      . ${package}/share/autojump/autojump.fish
    '';
  };
}
