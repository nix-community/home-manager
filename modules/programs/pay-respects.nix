{ config, lib, pkgs, ... }:
let
  inherit (lib)
    mkEnableOption mkPackageOption mkOption getExe optionalString mkIf;

  cfg = config.programs.pay-respects;
  payRespectsCmd = getExe cfg.package;

  payRespectsNushellOutput = lib.readFile (pkgs.runCommand "pr-output" { }
    "${pkgs.pay-respects}/bin/pay-respects nushell 1>$out || true");
  nushellIntegration =
    lib.head (lib.strings.splitString "\n" payRespectsNushellOutput);
in {
  meta.maintainers = [ lib.hm.maintainers.ALameLlama ];

  options.programs.pay-respects = {
    enable = mkEnableOption "pay-respects";

    package = mkPackageOption pkgs "pay-respects" { };

    enableBashIntegration = mkEnableOption "Bash integration" // {
      default = true;
    };

    enableZshIntegration = mkEnableOption "Zsh integration" // {
      default = true;
    };

    enableFishIntegration = mkEnableOption "Fish integration" // {
      default = true;
    };

    enableNushellIntegration = mkEnableOption "Nushell integration" // {
      default = true;
    };

    alias = mkOption {
      default = "f";
      description = "The alias used for the call to pay-respects.";
      type = lib.types.str;
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    programs = {
      bash.initExtra = ''
        ${optionalString cfg.enableBashIntegration ''
          eval "$(${payRespectsCmd} bash --alias ${cfg.alias})"
        ''}
      '';

      zsh.initExtra = ''
        ${optionalString cfg.enableZshIntegration ''
          eval "$(${payRespectsCmd} zsh --alias ${cfg.alias})"
        ''}
      '';

      fish.interactiveShellInit = ''
        ${optionalString cfg.enableFishIntegration ''
          ${payRespectsCmd} fish --alias ${cfg.alias} | source
        ''}
      '';

      nushell.extraConfig = ''
        ${optionalString cfg.enableNushellIntegration ''
          alias ${cfg.alias} = ${nushellIntegration}
        ''}
      '';
    };
  };
}
