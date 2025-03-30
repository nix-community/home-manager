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
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    programs = {
      fish.interactiveShellInit = lib.mkIf cfg.enableFishIntegration ''
        ${cfg.package}/bin/nix-your-shell fish | source
      '';

      nushell = lib.mkIf cfg.enableNushellIntegration {
        extraEnv = ''
          mkdir ${config.xdg.cacheHome}/nix-your-shell
          ${cfg.package}/bin/nix-your-shell nu | save --force ${config.xdg.cacheHome}/nix-your-shell/init.nu
        '';

        extraConfig = ''
          source ${config.xdg.cacheHome}/nix-your-shell/init.nu
        '';
      };

      zsh.initContent = lib.mkIf cfg.enableZshIntegration ''
        ${cfg.package}/bin/nix-your-shell zsh | source /dev/stdin
      '';
    };
  };
}
