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
    home.packages = [
      cfg.package
    ]
    ++ (lib.optionals cfg.enableNushellIntegration [
      (pkgs.runCommand "devenv-nu-hook" { } ''
        mkdir -p $out/share/nushell/vendor/autoload
        ${getExe cfg.package} hook nu > $out/share/nushell/vendor/autoload/devenv.nu
      '')
    ]);
    programs = {
      bash.initExtra = mkIf cfg.enableBashIntegration (
        # Using `mkAfter` to make it more likely to appear after other
        # manipulations of the prompt.
        mkAfter ''
          eval "$(${getExe cfg.package} hook bash)"
        ''
      );

      fish.interactiveShellInit = mkIf cfg.enableFishIntegration (
        # Using `mkAfter` to make it more likely to appear after other
        # manipulations of the prompt.
        mkAfter ''
          ${getExe cfg.package} hook fish | source
        ''
      );

      zsh.initContent = mkIf cfg.enableZshIntegration ''
        eval "$(${getExe cfg.package} hook zsh)"
      '';

      nushell = mkIf cfg.enableNushellIntegration {
        package = cfg.package;
      };
    };
  };
}
