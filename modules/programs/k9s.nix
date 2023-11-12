{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.k9s;
  yamlFormat = pkgs.formats.yaml { };

in {
  meta.maintainers = with maintainers; [ katexochen liyangau ];

  options.programs.k9s = {
    enable =
      mkEnableOption "k9s - Kubernetes CLI To Manage Your Clusters In Style";

    package = mkPackageOption pkgs "k9s" { };

    settings = mkOption {
      type = yamlFormat.type;
      default = { };
      description = ''
        Configuration written to {file}`$XDG_CONFIG_HOME/k9s/config.yml`. See
        <https://k9scli.io/topics/config/> for supported values.
      '';
      example = literalExpression ''
        k9s = {
          refreshRate = 2;
        };
      '';
    };

    skin = mkOption {
      type = yamlFormat.type;
      default = { };
      description = ''
        Skin written to {file}`$XDG_CONFIG_HOME/k9s/skin.yml`. See
        <https://k9scli.io/topics/skins/> for supported values.
      '';
      example = literalExpression ''
        k9s = {
          body = {
            fgColor = "dodgerblue";
          };
        };
      '';
    };

    aliases = mkOption {
      type = yamlFormat.type;
      default = { };
      description = ''
        Aliases written to {file}`$XDG_CONFIG_HOME/k9s/aliases.yml`. See
        <https://k9scli.io/topics/aliases/> for supported values.
      '';
      example = literalExpression ''
        alias = {
          # Use pp as an alias for Pod
          pp = "v1/pods";
        };
      '';
    };

    hotkey = mkOption {
      type = yamlFormat.type;
      default = { };
      description = ''
        Hotkeys written to {file}`$XDG_CONFIG_HOME/k9s/hotkey.yml`. See
        <https://k9scli.io/topics/hotkeys/> for supported values.
      '';
      example = literalExpression ''
        hotkey = {
          # Make sure this is camel case
          hotKey = {
            shift-0 = {
              shortCut = "Shift-0";
              description = "Viewing pods";
              command = "pods";
            };
          };
        };
      '';
    };

    plugin = mkOption {
      type = yamlFormat.type;
      default = { };
      description = ''
        Plugins written to {file}`$XDG_CONFIG_HOME/k9s/plugin.yml`. See
        <https://k9scli.io/topics/plugins/> for supported values.
      '';
      example = literalExpression ''
        plugin = {
          # Defines a plugin to provide a `ctrl-l` shortcut to
          # tail the logs while in pod view.
          fred = {
            shortCut = "Ctrl-L";
            description = "Pod logs";
            scopes = [ "po" ];
            command = "kubectl";
            background = false;
            args = [
              "logs"
              "-f"
              "$NAME"
              "-n"
              "$NAMESPACE"
              "--context"
              "$CLUSTER"
            ];
          };
        };
      '';
    };

    views = mkOption {
      type = yamlFormat.type;
      default = { };
      description = ''
        Resource column views written to {file}`$XDG_CONFIG_HOME/k9s/views.yml`.
        See <https://k9scli.io/topics/columns/> for supported values.
      '';
      example = literalExpression ''
        k9s = {
          views = {
            "v1/pods" = {
              columns = [
                "AGE"
                "NAMESPACE"
                "NAME"
                "IP"
                "NODE"
                "STATUS"
                "READY"
              ];
            };
          };
        };
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."k9s/config.yml" = mkIf (cfg.settings != { }) {
      source = yamlFormat.generate "k9s-config" cfg.settings;
    };

    xdg.configFile."k9s/skin.yml" = mkIf (cfg.skin != { }) {
      source = yamlFormat.generate "k9s-skin" cfg.skin;
    };

    xdg.configFile."k9s/aliases.yml" = mkIf (cfg.aliases != { }) {
      source = yamlFormat.generate "k9s-aliases" cfg.aliases;
    };

    xdg.configFile."k9s/hotkey.yml" = mkIf (cfg.hotkey != { }) {
      source = yamlFormat.generate "k9s-hotkey" cfg.hotkey;
    };

    xdg.configFile."k9s/plugin.yml" = mkIf (cfg.plugin != { }) {
      source = yamlFormat.generate "k9s-plugin" cfg.plugin;
    };

    xdg.configFile."k9s/views.yml" = mkIf (cfg.views != { }) {
      source = yamlFormat.generate "k9s-views" cfg.views;
    };
  };
}
