{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.zellij;
  yamlFormat = pkgs.formats.yaml { };
in {
  meta.maintainers = [ hm.maintainers.mainrs ];

  options.programs.zellij = {
    enable = mkEnableOption "Zellij";

    package = mkOption {
      type = types.package;
      default = pkgs.zellij;
      defaultText = literalExpression "pkgs.zellij";
      description = ''
        The Zellij package to install.
      '';
    };

    settings = mkOption {
      type = yamlFormat.type;
      default = { };
      example = literalExpression ''
        {
          theme = "custom";
          themes.custom.fg = "#ffffff";
        }
      '';
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/zellij/config.kdl`.

        If `programs.zellij.package.version` is older than 0.32.0, then
        the configuration is written to {file}`$XDG_CONFIG_HOME/zellij/config.yaml`.

        See <https://zellij.dev/documentation> for the full
        list of options.
      '';
    };

    attachExistingSession = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to attach to the default session after being autostarted if a Zellij session already exists.

        Requires shell integration to be enabled to have effect.
      '';
    };

    exitShellOnExit = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to exit the shell when Zellij exits after being autostarted.

        Requires shell integration to be enabled to have effect.
      '';
    };

    enableBashIntegration =
      lib.hm.shell.mkBashIntegrationOption { inherit config; };

    enableFishIntegration =
      lib.hm.shell.mkFishIntegrationOption { inherit config; };

    enableZshIntegration =
      lib.hm.shell.mkZshIntegrationOption { inherit config; };
  };

  config = let
    shellIntegrationEnabled = (cfg.enableBashIntegration
      || cfg.enableZshIntegration || cfg.enableFishIntegration);
  in mkIf cfg.enable {
    home.packages = [ cfg.package ];

    # Zellij switched from yaml to KDL in version 0.32.0:
    # https://github.com/zellij-org/zellij/releases/tag/v0.32.0
    xdg.configFile."zellij/config.yaml" = mkIf
      (cfg.settings != { } && (versionOlder cfg.package.version "0.32.0")) {
        source = yamlFormat.generate "zellij.yaml" cfg.settings;
      };

    xdg.configFile."zellij/config.kdl" = mkIf
      (cfg.settings != { } && (versionAtLeast cfg.package.version "0.32.0")) {
        text = lib.hm.generators.toKDL { } cfg.settings;
      };

    programs.bash.initExtra = mkIf cfg.enableBashIntegration ''
      eval "$(${getExe cfg.package} setup --generate-auto-start bash)"
    '';

    programs.zsh.initExtra = mkIf cfg.enableZshIntegration ''
      eval "$(${getExe cfg.package} setup --generate-auto-start zsh)"
    '';

    programs.fish.interactiveShellInit = mkIf cfg.enableFishIntegration ''
      eval (${
        getExe cfg.package
      } setup --generate-auto-start fish | string collect)
    '';

    home.sessionVariables = mkIf shellIntegrationEnabled {
      ZELLIJ_AUTO_ATTACH =
        if cfg.attachExistingSession then "true" else "false";
      ZELLIJ_AUTO_EXIT = if cfg.exitShellOnExit then "true" else "false";
    };

    warnings =
      optional (cfg.attachExistingSession && !shellIntegrationEnabled) ''
        You have enabled `programs.zellij.attachExistingSession`, but none of the shell integrations are enabled.
        This option will have no effect.
      '' ++ optional (cfg.exitShellOnExit && !shellIntegrationEnabled) ''
        You have enabled `programs.zellij.exitShellOnExit`, but none of the shell integrations are enabled.
        This option will have no effect.
      '';
  };
}
