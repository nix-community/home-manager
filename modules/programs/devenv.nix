{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkPackageOption
    mkIf
    mkAfter
    getExe
    ;

  cfg = config.programs.devenv;

in
{
  meta.maintainers = with lib.maintainers; [
    leiserfg
  ];

  options.programs.devenv = {
    enable = mkEnableOption "devenv, Fast, Declarative, Reproducible and Composable Developer Environments using Nix";

    package = mkPackageOption pkgs "devenv" { };

    enableBashIntegration = lib.hm.shell.mkBashIntegrationOption { inherit config; };

    enableFishIntegration = lib.hm.shell.mkFishIntegrationOption { inherit config; };

    enableNushellIntegration = lib.hm.shell.mkNushellIntegrationOption { inherit config; };

    enableZshIntegration = lib.hm.shell.mkZshIntegrationOption { inherit config; };

  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];
    programs = {
      bash.initExtra = mkIf cfg.enableBashIntegration (mkAfter ''
        eval "$(${getExe cfg.package} hook bash)"
      '');

      fish.interactiveShellInit = mkIf cfg.enableFishIntegration (mkAfter ''
        ${getExe cfg.package} hook fish | source
      '');

      zsh.initContent = mkIf cfg.enableZshIntegration ''
        eval "$(${getExe cfg.package} hook zsh)"
      '';

      nushell = mkIf cfg.enableNushellIntegration {
        extraConfig = "source ${
          pkgs.runCommand "devenv-nushell-config.nu" { } ''
            ${getExe cfg.package} hook nu > $out
          ''
        } ";
      };
    };
  };
}
