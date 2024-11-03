{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.zellij;
  yamlFormat = pkgs.formats.yaml { };
  zellijCmd = getExe cfg.package;

  autostartOnShellStartModule = types.submodule {
    options = {
      enable = mkEnableOption "" // {
        description = ''
          Whether to autostart Zellij session on shell creation.
        '';
      };

      attachExistingSession = mkEnableOption "" // {
        description = ''
          Whether to attach to the default session after being autostarted if a Zellij session already exists.
        '';
      };

      exitShellOnExit = mkEnableOption "" // {
        description = ''
          Whether to exit the shell when Zellij exits after being autostarted.
        '';
      };
    };
  };
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

    autostartOnShellStart = mkOption {
      type = types.nullOr autostartOnShellStartModule;
      default = null;
      description = ''
        Options related to autostarting Zellij on shell creation.
        Requires enable<Shell>Integration to apply to the respective <Shell>.
      '';
    };

    enableBashIntegration =
      lib.hm.shell.mkBashIntegrationOption { inherit config; };

    enableFishIntegration =
      lib.hm.shell.mkFishIntegrationOption { inherit config; };

    enableZshIntegration =
      lib.hm.shell.mkZshIntegrationOption { inherit config; };
  };

  config = mkIf cfg.enable {
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

    programs.zsh.initExtra = mkIf (cfg.enableZshIntegration)
      (if cfg.autostartOnShellStart.enable then (mkOrder 200 ''
        eval "$(${zellijCmd} setup --generate-auto-start zsh)"
      '') else
        "");

    programs.fish.interactiveShellInit = mkIf (cfg.enableFishIntegration)
      (if cfg.autostartOnShellStart.enable then ''
        eval (${zellijCmd} setup --generate-auto-start fish | string collect)
      '' else
        "");

    programs.bash.initExtra = mkIf (cfg.enableBashIntegration)
      (if cfg.autostartOnShellStart.enable then ''
        eval "$(${zellijCmd} setup --generate-auto-start bash)"
      '' else
        "");

    home.sessionVariables = mkIf cfg.autostartOnShellStart.enable {
      ZELLIJ_AUTO_ATTACH =
        if cfg.autostartOnShellStart.attachExistingSession then
          "true"
        else
          "false";
      ZELLIJ_AUTO_EXIT =
        if cfg.autostartOnShellStart.exitShellOnExit then "true" else "false";
    };
  };
}
