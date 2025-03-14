{ config, lib, pkgs, ... }:
let
  inherit (lib) mkEnableOption mkPackageOption getExe optionalString mkIf;

  cfg = config.programs.pay-respects;
  payRespectsCmd = getExe cfg.package;
in {
  meta.maintainers = [ lib.hm.maintainers.ALameLlama ];

  options.programs.pay-respects = {
    enable = mkEnableOption "pay-respects";

    package = mkPackageOption pkgs "pay-respects" { };

    enableBashIntegration =
      lib.hm.shell.mkBashIntegrationOption { inherit config; };

    enableFishIntegration =
      lib.hm.shell.mkFishIntegrationOption { inherit config; };

    enableNushellIntegration =
      lib.hm.shell.mkNushellIntegrationOption { inherit config; };

    enableZshIntegration =
      lib.hm.shell.mkZshIntegrationOption { inherit config; };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    programs = {
      bash.initExtra = ''
        ${optionalString cfg.enableBashIntegration ''
          eval "$(${payRespectsCmd} bash --alias)"
        ''}
      '';

      zsh.initExtra = ''
        ${optionalString cfg.enableZshIntegration ''
          eval "$(${payRespectsCmd} zsh --alias)"
        ''}
      '';

      fish.interactiveShellInit = ''
        ${optionalString cfg.enableFishIntegration ''
          ${payRespectsCmd} fish --alias | source
        ''}
      '';

      nushell.extraConfig = ''
        ${optionalString cfg.enableNushellIntegration ''
          ${payRespectsCmd} nushell --alias [<alias>]
        ''}
      '';
    };
  };
}
