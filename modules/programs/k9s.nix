{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    literalExpression
    mkIf
    mkOption
    types
    ;

  cfg = config.programs.k9s;
  yamlFormat = pkgs.formats.yaml { };
  inherit (pkgs.stdenv.hostPlatform) isDarwin;

in
{
  meta.maintainers = with lib.maintainers; [
    liyangau
    lib.hm.maintainers.LucasWagler
  ];

  imports = [
    (lib.mkRenamedOptionModule
      [ "programs" "k9s" "skin" ]
      [
        "programs"
        "k9s"
        "skins"
        "skin"
      ]
    )
    (lib.mkRenamedOptionModule [ "programs" "k9s" "hotkey" ] [ "programs" "k9s" "hotKeys" ])
    (lib.mkRenamedOptionModule [ "programs" "k9s" "plugin" ] [ "programs" "k9s" "plugins" ])
  ];

  options.programs.k9s = {
    enable = lib.mkEnableOption "k9s - Kubernetes CLI To Manage Your Clusters In Style";

    package = lib.mkPackageOption pkgs "k9s" { nullable = true; };

    settings = mkOption {
      type = yamlFormat.type;
      default = { };
      description = ''
        Configuration written to {file}`$XDG_CONFIG_HOME/k9s/config.yaml` (linux)
        or {file}`Library/Application Support/k9s/config.yaml` (darwin), See
        <https://k9scli.io/topics/config/> for supported values.
      '';
      example = literalExpression ''
        k9s = {
          refreshRate = 2;
        };
      '';
    };

    skins = mkOption {
      type = with types; attrsOf (either yamlFormat.type path);
      default = { };
      description = ''
        Skin files written to {file}`$XDG_CONFIG_HOME/k9s/skins/` (linux)
        or {file}`Library/Application Support/k9s/skins/` (darwin). See
        <https://k9scli.io/topics/skins/> for supported values.
      '';
      example = literalExpression ''
        {
          my_blue_skin = {
            k9s = {
              body = {
                fgColor = "dodgerblue";
              };
            };
          };
          my_red_skin = ./red_skin.yaml;
        }
      '';
    };

    aliases = mkOption {
      type = yamlFormat.type;
      default = { };
      description = ''
        Aliases written to {file}`$XDG_CONFIG_HOME/k9s/aliases.yaml` (linux)
        or {file}`Library/Application Support/k9s/aliases.yaml` (darwin). See
        <https://k9scli.io/topics/aliases/> for supported values.
      '';
      example = literalExpression ''
        {
          # Use pp as an alias for Pod
          pp = "v1/pods";
        }
      '';
    };

    hotKeys = mkOption {
      type = yamlFormat.type;
      default = { };
      description = ''
        Hotkeys written to {file}`$XDG_CONFIG_HOME/k9s/hotkeys.yaml` (linux)
        or {file}`Library/Application Support/k9s/hotkeys.yaml` (darwin). See
        <https://k9scli.io/topics/hotkeys/> for supported values.
      '';
      example = literalExpression ''
        {
          shift-0 = {
            shortCut = "Shift-0";
            description = "Viewing pods";
            command = "pods";
          };
        }
      '';
    };

    plugins = mkOption {
      type = yamlFormat.type;
      default = { };
      description = ''
        Plugins written to {file}`$XDG_CONFIG_HOME/k9s/plugins.yaml (linux)`
        or {file}`Library/Application Support/k9s/plugins.yaml` (darwin). See
        <https://k9scli.io/topics/plugins/> for supported values.
      '';
      example = literalExpression ''
        {
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
        }
      '';
    };

    views = mkOption {
      type = yamlFormat.type;
      default = { };
      description = ''
        Resource column views written to
        {file}`$XDG_CONFIG_HOME/k9s/views.yaml (linux)`
        or {file}`Library/Application Support/k9s/views.yaml` (darwin).
        See <https://k9scli.io/topics/columns/> for supported values.
      '';
      example = literalExpression ''
        {
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
        }
      '';
    };
  };

  config =
    let
      skinSetting =
        if (!(cfg.settings ? k9s.ui.skin) && cfg.skins != { }) then
          {
            k9s.ui.skin = "${builtins.elemAt (builtins.attrNames cfg.skins) 0}";
          }
        else
          { };

      skinFiles = lib.mapAttrs' (
        name: value:
        lib.nameValuePair
          (
            if !(isDarwin && !config.xdg.enable) then
              "k9s/skins/${name}.yaml"
            else
              "Library/Application Support/k9s/skins/${name}.yaml"
          )
          {
            source =
              if lib.types.path.check value then value else yamlFormat.generate "k9s-skin-${name}.yaml" value;
          }
      ) cfg.skins;

      enableXdgConfig = !isDarwin || config.xdg.enable;

    in
    mkIf cfg.enable {
      home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];
      warnings =
        (lib.optional (cfg.aliases ? alias)
          "Nested 'alias' key in programs.k9s.aliases is deprecated, move the contents directly under programs.k9s.aliases"
        )
        ++ (lib.optional (cfg.plugins ? plugin)
          "Nested 'plugin' key in programs.k9s.plugins is deprecated, move the contents directly under programs.k9s.plugins"
        )
        ++ (lib.optional (cfg.views ? k9s.views)
          "Nested 'k9s.views' structure in programs.k9s.views is deprecated, move the contents directly under programs.k9s.views"
        );

      xdg.configFile = mkIf enableXdgConfig (
        {
          "k9s/config.yaml" = mkIf (cfg.settings != { }) {
            source = yamlFormat.generate "k9s-config" (lib.recursiveUpdate skinSetting cfg.settings);
          };

          "k9s/aliases.yaml" = mkIf (cfg.aliases != { }) {
            source = yamlFormat.generate "k9s-aliases" { inherit (cfg) aliases; };
          };

          "k9s/hotkeys.yaml" = mkIf (cfg.hotKeys != { }) {
            source = yamlFormat.generate "k9s-hotkeys" { inherit (cfg) hotKeys; };
          };

          "k9s/plugins.yaml" = mkIf (cfg.plugins != { }) {
            source = yamlFormat.generate "k9s-plugins" { inherit (cfg) plugins; };
          };

          "k9s/views.yaml" = mkIf (cfg.views != { }) {
            source = yamlFormat.generate "k9s-views" { inherit (cfg) views; };
          };
        }
        // skinFiles
      );

      home.file = mkIf (!enableXdgConfig) (
        {
          "Library/Application Support/k9s/config.yaml" = mkIf (cfg.settings != { }) {
            source = yamlFormat.generate "k9s-config" (lib.recursiveUpdate skinSetting cfg.settings);
          };

          "Library/Application Support/k9s/aliases.yaml" = mkIf (cfg.aliases != { }) {
            source = yamlFormat.generate "k9s-aliases" { inherit (cfg) aliases; };
          };

          "Library/Application Support/k9s/hotkeys.yaml" = mkIf (cfg.hotKeys != { }) {
            source = yamlFormat.generate "k9s-hotkeys" { inherit (cfg) hotKeys; };
          };

          "Library/Application Support/k9s/plugins.yaml" = mkIf (cfg.plugins != { }) {
            source = yamlFormat.generate "k9s-plugins" { inherit (cfg) plugins; };
          };

          "Library/Application Support/k9s/views.yaml" = mkIf (cfg.views != { }) {
            source = yamlFormat.generate "k9s-views" { inherit (cfg) views; };
          };
        }
        // skinFiles
      );
    };
}
