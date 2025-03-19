{ config, lib, pkgs, ... }:
let cfg = config.programs.nix-your-shell;
in {
  meta.maintainers = [ lib.maintainers.terlar ];

  options.programs.nix-your-shell = {
    enable = lib.mkEnableOption ''
      {command}`nix-your-shell`, a wrapper for `nix develop` or `nix-shell`
      to retain the same shell inside the new environment'';

    package = lib.mkPackageOption pkgs "nix-your-shell" { };

    enableFishIntegration =
      lib.hm.shell.mkFishIntegrationOption { inherit config; };

    enableNushellIntegration =
      lib.hm.shell.mkNushellIntegrationOption { inherit config; };

    enableZshIntegration =
      lib.hm.shell.mkZshIntegrationOption { inherit config; };

    enableNom = lib.mkEnableOption "nom (nix-output-monitor) integration";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ]
      ++ (lib.optionals cfg.enableNom [ pkgs.nix-output-monitor ]);

    programs = let
      argsForShell = shell:
        lib.concatStringsSep " "
        ([ ] ++ (lib.optional cfg.enableNom "--nom") ++ [ "${shell}" ]);
    in {
      fish.interactiveShellInit = lib.mkIf cfg.enableFishIntegration ''
        ${cfg.package}/bin/nix-your-shell ${argsForShell "fish"} | source
      '';

      nushell = lib.mkIf cfg.enableNushellIntegration {
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

      zsh.initExtra = lib.mkIf cfg.enableZshIntegration ''
        ${cfg.package}/bin/nix-your-shell ${
          argsForShell "zsh"
        } | source /dev/stdin
      '';
    };
  };
}
