{ config, lib, pkgs, ... }:
let
  inherit (lib) mkIf;

  cfg = config.programs.pazi;

in {
  meta.maintainers = [ ];

  options.programs.pazi = {
    enable = lib.mkEnableOption "pazi";

    package = lib.mkPackageOption pkgs "pazi" { };

    enableBashIntegration =
      lib.hm.shell.mkBashIntegrationOption { inherit config; };

    enableFishIntegration =
      lib.hm.shell.mkFishIntegrationOption { inherit config; };

    enableZshIntegration =
      lib.hm.shell.mkZshIntegrationOption { inherit config; };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    programs.bash.initExtra = mkIf cfg.enableBashIntegration ''
      eval "$(${lib.getExe cfg.package} init bash)"
    '';

    programs.zsh.initContent = mkIf cfg.enableZshIntegration ''
      eval "$(${lib.getExe cfg.package} init zsh)"
    '';

    programs.fish.shellInit = mkIf cfg.enableFishIntegration ''
      ${lib.getExe cfg.package} init fish | source
    '';
  };
}
