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
  yamlFormat = pkgs.formats.yaml { };

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

    settings = lib.mkOption {
      inherit (yamlFormat) type;
      default = { };
      example = {
        shell.prompt_prefix = false;
        tui.statusline.enabled = false;
      };
      description = ''
        Configuration written to {file}`$XDG_CONFIG_HOME/devenv/config.yaml`.

        See <https://devenv.sh/tui-customization/> for
        available options and documentation.
      '';
    };

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
    xdg.configFile."devenv/config.yaml" = lib.mkIf (cfg.settings != { }) {
      source = yamlFormat.generate "config.yaml" ({ version = 1; } // cfg.settings);
    };
  };
}
