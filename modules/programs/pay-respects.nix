{ config, lib, pkgs, ... }:
let
  cfg = config.programs.pay-respects;
  payRespectsCmd = lib.getExe cfg.package;
  cfgOptions = lib.concatStringsSep " " cfg.options;
in {
  meta.maintainers = [ lib.hm.maintainers.ALameLlama ];

  options.programs.pay-respects = {
    enable = lib.mkEnableOption "pay-respects";

    package = lib.mkPackageOption pkgs "pay-respects" { };

    options = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "--alias" ];
      example = [ "--alias" "f" ];
      description = ''
        List of options to pass to pay-respects <shell>.
      '';
    };

    enableBashIntegration =
      lib.hm.shell.mkBashIntegrationOption { inherit config; };

    enableFishIntegration =
      lib.hm.shell.mkFishIntegrationOption { inherit config; };

    enableNushellIntegration =
      lib.hm.shell.mkNushellIntegrationOption { inherit config; };

    enableZshIntegration =
      lib.hm.shell.mkZshIntegrationOption { inherit config; };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    programs = {
      bash.initExtra = lib.mkIf cfg.enableBashIntegration ''
        eval "$(${payRespectsCmd} bash ${cfgOptions})"
      '';

      zsh.initContent = lib.mkIf cfg.enableZshIntegration ''
        eval "$(${payRespectsCmd} zsh ${cfgOptions})"
      '';

      fish.interactiveShellInit = lib.mkIf cfg.enableFishIntegration ''
        ${payRespectsCmd} fish ${cfgOptions} | source
      '';

      nushell.extraConfig = lib.mkIf cfg.enableNushellIntegration ''
        source ${
          pkgs.runCommand "pay-respects-nushell-config.nu" { } ''
            ${payRespectsCmd} nushell ${cfgOptions} >> "$out"
          ''
        }
      '';
    };
  };
}
