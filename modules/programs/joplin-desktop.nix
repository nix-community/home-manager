{
  config,
  lib,
  options,
  pkgs,
  ...
}:
let
  cfg = config.programs.joplin-desktop;
  jsonFormat = pkgs.formats.json { };
  settingsType = lib.types.attrsOf jsonFormat.type;
in
{
  imports =
    let
      overlay = lib.hm.deprecations.mkSettingsOverlay {
        inherit options;
        from = [
          "programs"
          "joplin-desktop"
          "extraConfig"
        ];
        to = [
          "programs"
          "joplin-desktop"
          "settings"
        ];
      };

      convertSync =
        name: values:
        args@{ options, ... }:
        let
          from = [
            "programs"
            "joplin-desktop"
            "sync"
            name
          ];
          key = "sync.${name}";
          changed = lib.mkChangedOptionModule from [ "programs" "joplin-desktop" "settings" ] (
            config:
            lib.optionalAttrs (!(builtins.elem key overlay.keys)) {
              ${key} = lib.mkOptionDefault values.${config.programs.joplin-desktop.sync.${name}};
            }
          ) args;
        in
        changed
        // {
          options = lib.recursiveUpdate changed.options (
            lib.setAttrByPath from {
              default = "undefined";
            }
          );
          config = lib.mkIf (
            (lib.getAttrFromPath from options).highestPrio < (lib.mkOptionDefault null).priority
          ) changed.config;
        };
    in
    [
      overlay.module
      (
        args@{ options, ... }:
        let
          from = [
            "programs"
            "joplin-desktop"
            "general"
            "editor"
          ];
          old = lib.getAttrFromPath from options;
        in
        lib.doRename
          {
            inherit from;
            to = [
              "programs"
              "joplin-desktop"
              "settings"
              "editor"
            ];
            visible = false;
            warn = true;
            use = _: cfg.settings.editor or null;
            condition = old.isDefined && old.highestPrio <= (lib.mkOptionDefault null).priority;
          }
          (
            args
            // {
              # The old extraConfig overlay won even over a forced editor. Keep the
              # winning source definitions, but forward them as compatibility defaults.
              options = lib.recursiveUpdate options (
                lib.setAttrByPath from {
                  highestPrio = (lib.mkOptionDefault null).priority;
                  definitions = if builtins.elem "editor" overlay.keys then [ ] else old.definitions;
                }
              );
            }
          )
      )
      (convertSync "target" {
        undefined = null;
        none = 0;
        file-system = 2;
        onedrive = 3;
        nextcloud = 5;
        webdav = 6;
        dropbox = 7;
        s3 = 8;
        joplin-server = 9;
        joplin-cloud = 10;
      })
      (convertSync "interval" {
        undefined = null;
        disabled = 0;
        "5m" = 300;
        "10m" = 600;
        "30m" = 1800;
        "1h" = 3600;
        "12h" = 43200;
        "1d" = 86400;
      })
    ];

  meta.maintainers = [ lib.hm.maintainers.zorrobert ];

  options.programs.joplin-desktop = {
    enable = lib.mkEnableOption "joplin-desktop";
    package = lib.mkPackageOption pkgs "joplin-desktop" { };

    settings = lib.mkOption {
      type = settingsType;
      default = { };
      example = {
        "newNoteFocus" = "title";
        "markdown.plugin.mark" = true;
        "sync.target" = 7;
        "sync.interval" = 600;
      };
      description = ''
        Settings merged into the writable
        {file}`$XDG_CONFIG_HOME/joplin-desktop/settings.json` during activation.
        Settings not configured here are preserved.

        Dotted names such as `"sync.interval"` are literal JSON keys.
        Sync targets and intervals use Joplin's numeric values. For example,
        target `7` selects Dropbox and interval `600` selects ten minutes.
        Target `0` disables sync and interval `0` disables automatic sync.

        Top-level null values and empty strings are omitted, leaving existing
        application settings unchanged. False, zero, empty lists, and empty
        objects are written. Deprecated editor and sync options supply
        compatibility defaults that explicit settings can override.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    home.activation.activateJoplinDesktopConfig =
      let
        configPath = "${config.xdg.configHome}/joplin-desktop/settings.json";
        newConfig = jsonFormat.generate "joplin-settings.json" (
          lib.filterAttrs (_: value: value != null && value != "") cfg.settings
        );
      in
      lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        # Ensure that settings.json exists.
        mkdir -p ${dirOf configPath}
        touch ${configPath}
        # Config has to be written to temporary variable because jq cannot edit files in place.
        config="$(jq -s '.[0] + .[1]' ${configPath} ${newConfig})"
        printf '%s\n' "$config" > ${configPath}
        unset config
      '';
  };
}
