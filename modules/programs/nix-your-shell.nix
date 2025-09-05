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
      to retain the same shell inside the new environment'';

    package = lib.mkPackageOption pkgs "nix-your-shell" { };

    enableFishIntegration = lib.hm.shell.mkFishIntegrationOption { inherit config; };

    enableNushellIntegration = lib.hm.shell.mkNushellIntegrationOption { inherit config; };

    enableZshIntegration = lib.hm.shell.mkZshIntegrationOption { inherit config; };

    nix-output-monitor = {
      enable = lib.mkEnableOption ''
        [nix-output-monitor](https://github.com/maralorn/nix-output-monitor).
        Pipe your nix-build output through the nix-output-monitor a.k.a nom to get additional information while building
      '';

      package = lib.mkPackageOption pkgs "nix-output-monitor" { };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      cfg.package
      (lib.mkIf cfg.nix-output-monitor.enable cfg.nix-output-monitor.package)
    ];

    programs =
      let
        nom = if cfg.nix-output-monitor.enable then "--nom" else "";
      in
      {
        fish.interactiveShellInit = lib.mkIf cfg.enableFishIntegration ''
          ${lib.getExe cfg.package} ${nom} fish | source
        '';

        nushell = lib.mkIf cfg.enableNushellIntegration {
          extraConfig = ''
            source ${
              pkgs.runCommand "nix-your-shell-nushell-config.nu" { } ''
                ${lib.getExe cfg.package} ${nom} nu >> "$out"
              ''
            }
          '';
        };

        zsh.initContent = lib.mkIf cfg.enableZshIntegration ''
          ${lib.getExe cfg.package} ${nom} zsh | source /dev/stdin
        '';
      };
  };
}
