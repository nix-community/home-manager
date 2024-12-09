{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.nix-your-shell;

in {
  meta.maintainers = [ maintainers.terlar ];

  options.programs.nix-your-shell = {
    enable = mkEnableOption ''
      {command}`nix-your-shell`, a wrapper for `nix develop` or `nix-shell`
      to retain the same shell inside the new environment'';

    package = mkPackageOption pkgs "nix-your-shell" { };

    enableFishIntegration = mkEnableOption "Fish integration" // {
      default = true;
    };

    enableNushellIntegration = mkEnableOption "Nushell integration" // {
      default = true;
    };

    enableZshIntegration = mkEnableOption "Zsh integration" // {
      default = true;
    };

    enableNom = mkEnableOption "nom (nix-output-monitor) integration";
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ]
      ++ (optionals cfg.enableNom [ pkgs.nix-output-monitor ]);

    programs = let
      argsForShell = shell:
        concatStringsSep " "
        ([ ] ++ (optional cfg.enableNom "--nom") ++ [ "${shell}" ]);
    in {
      fish.interactiveShellInit = mkIf cfg.enableFishIntegration ''
        ${cfg.package}/bin/nix-your-shell ${argsForShell "fish"} | source
      '';

      nushell = mkIf cfg.enableNushellIntegration {
        extraEnv = ''
          mkdir ${config.xdg.cacheHome}/nix-your-shell
          ${cfg.package}/bin/nix-your-shell ${
            argsForShell "nu"
          } | save --force ${config.xdg.cacheHome}/nix-your-shell/init.nu
        '';

        extraConfig = ''
          source ${config.xdg.cacheHome}/nix-your-shell/init.nu
        '';
      };

      zsh.initExtra = mkIf cfg.enableZshIntegration ''
        ${cfg.package}/bin/nix-your-shell ${
          argsForShell "zsh"
        } | source /dev/stdin
      '';
    };
  };
}
