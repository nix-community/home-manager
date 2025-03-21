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
      fish.interactiveShellInit = mkIf cfg.enableFishIntegration ''
        ${lib.getExe cfg.package} fish | source
      '';

      nushell = mkIf cfg.enableNushellIntegration {
        extraConfig = ''
          source ${
            pkgs.runCommand "nix-your-shell-nushell-config" { } ''
              ${lib.getExe cfg.package} nu >> "$out"
            ''
          }
        '';
      };

      zsh.initContent = mkIf cfg.enableZshIntegration ''
        ${lib.getExe cfg.package} zsh | source /dev/stdin
      '';
    };
  };
}
