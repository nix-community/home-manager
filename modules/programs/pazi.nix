{ config, lib, pkgs, ... }:
let
  inherit (lib) mkIf;

  cfg = config.programs.pazi;

in {
  meta.maintainers = [ ];

  options.programs.pazi = {
    enable = lib.mkEnableOption "pazi";

    enableBashIntegration =
      lib.hm.shell.mkBashIntegrationOption { inherit config; };

    enableFishIntegration =
      lib.hm.shell.mkFishIntegrationOption { inherit config; };

    enableZshIntegration =
      lib.hm.shell.mkZshIntegrationOption { inherit config; };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.pazi ];

    programs.bash.initExtra = mkIf cfg.enableBashIntegration ''
      eval "$(${pkgs.pazi}/bin/pazi init bash)"
    '';

    programs.zsh.initContent = mkIf cfg.enableZshIntegration ''
      eval "$(${pkgs.pazi}/bin/pazi init zsh)"
    '';

    programs.fish.shellInit = mkIf cfg.enableFishIntegration ''
      ${pkgs.pazi}/bin/pazi init fish | source
    '';
  };
}
