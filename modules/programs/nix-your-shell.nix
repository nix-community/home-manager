{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.nix-your-shell;
in
{
  meta.maintainers = [ lib.maintainers.terlar ];

  options.programs.nix-your-shell = {
    enable = lib.mkEnableOption ''
      {command}`nix-your-shell`, a wrapper for `nix develop` or `nix-shell`
      to retain the same shell inside the new environment
    '';

    package = lib.mkPackageOption pkgs "nix-your-shell" { };

    enableFishIntegration = lib.hm.shell.mkFishIntegrationOption { inherit config; };

    enableNushellIntegration = lib.hm.shell.mkNushellIntegrationOption { inherit config; };

    enableZshIntegration = lib.hm.shell.mkZshIntegrationOption { inherit config; };

    enableNixOutputMonitorIntegration = lib.mkOption {
      type = lib.types.bool;
      default = config.programs.nix-output-monitor.enable;
      defaultText = lib.literalExpression "config.programs.nix-output-monitor.enable";
      description = ''
        Enable integration with nix-output-monitor, to use `nom` (`nix-output-monitor`) instead of `nix` for running
        commands.
      '';
      example = true;
    };
  };

  config = lib.mkIf cfg.enable {

    home.packages = [ cfg.package ];

    programs =
      let
        nom = if cfg.enableNixOutputMonitorIntegration then " --nom" else "";
      in
      {
        fish.interactiveShellInit = lib.mkIf cfg.enableFishIntegration ''
          ${lib.getExe cfg.package}${nom} fish | source
        '';

        nushell = lib.mkIf cfg.enableNushellIntegration {
          extraConfig = ''
            source ${
              pkgs.runCommand "nix-your-shell-nushell-config.nu" { } ''
                ${lib.getExe cfg.package}${nom} nu >> "$out"
              ''
            }
          '';
        };

        zsh.initContent = lib.mkIf cfg.enableZshIntegration ''
          ${lib.getExe cfg.package}${nom} zsh | source /dev/stdin
        '';
      };

    assertions = [
      {
        assertion = cfg.enableNixOutputMonitorIntegration -> config.programs.nix-output-monitor.enable;
        message = "If programs.nix-your-shell.enableNixOutputMonitorIntegration is `true`, nix-output-monitor must be enabled as well (programs.nix-output-monitor.enable must be `true`).";
      }
    ];
  };
}
