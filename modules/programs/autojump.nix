{ config, lib, pkgs, ... }:
let
  cfg = config.programs.autojump;

  inherit (lib) mkIf;
in {
  meta.maintainers = [ lib.maintainers.evanjs ];

  options.programs.autojump = {
    enable = lib.mkEnableOption "autojump";

    package = lib.mkPackageOption pkgs "autojump" { };

    enableBashIntegration =
      lib.hm.shell.mkBashIntegrationOption { inherit config; };

    enableFishIntegration =
      lib.hm.shell.mkFishIntegrationOption { inherit config; };

    enableZshIntegration =
      lib.hm.shell.mkZshIntegrationOption { inherit config; };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    programs.bash.initExtra = mkIf cfg.enableBashIntegration (lib.mkBefore ''
      . ${cfg.package}/share/autojump/autojump.bash
    '');

    programs.zsh.initContent = mkIf cfg.enableZshIntegration ''
      . ${cfg.package}/share/autojump/autojump.zsh
    '';

    programs.fish.interactiveShellInit = mkIf cfg.enableFishIntegration ''
      . ${cfg.package}/share/autojump/autojump.fish
    '';
  };
}
