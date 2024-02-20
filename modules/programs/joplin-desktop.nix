{ config, lib, pkgs, ... }:

let

  cfg = config.programs.joplin-desktop;

  jsonFormat = pkgs.formats.json { };

  # config path is the same for linux and mac
  configPath = (config.home.homeDirectory + "/.config/joplin-desktop");

in {
  options.programs.joplin-desktop = {
    enable = lib.mkEnableOption "joplin-desktop";

    package = lib.mkPackageOption pkgs "joplin-desktop" { };

    extraConfig = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = ''
        Use this to add other options to the Joplin config file. Settings are written in JSON, so "sync.interval":600 would be written as "sync.interval" = 600'';
      example = {
        "newNoteFocus" = "title";
        "markdown.plugin.mark" = true;
      };
    };

    ### General
    general = {
      editor = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "kate";
        description =
          "The editor command (may include arguments) that will be used to open a note. If none is provided Joplin will try to auto-detect the default editor.";
      };
    };

    ### Sync
    sync = {
      target = lib.mkOption {
        type = lib.types.enum [
          null
          "none"
          "file-system"
          "onedrive"
          "nextcloud"
          "webdav"
          "dropbox"
          "s3"
          "joplin-server"
          "joplin-cloud"
        ];
        default = null;
        description = "What is the type of sync target.";
        example = "dropbox";
      };

      interval = lib.mkOption {
        type = lib.types.enum [ null 300 600 1800 3600 43200 86400 ];
        default = null;
        description = ''
          Sync Interval in seconds. Only values shown as options in the settings are valid.
          Disabled: 0
          5 Min: 300
          10 Min: 600
          30 Min: 1800
          1 hour: 3600
          12 Hours: 43200
          24 Hours: 86400
        '';
        example = 600;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    home.activation = {
      hm-activate-joplin-desktop-config =
        let
          newConfig = jsonFormat.generate "joplin-settings.json" (
            lib.attrsets.filterAttrs (n: v: (v != null) && (v != "")) (
              {
                # TODO: find a better way to convert nix attribute names to strings:
                # sync.interval = ... -> "sync.interval" = ...
                "editor" = config.programs.joplin-desktop.general.editor;
                "sync.interval" = config.programs.joplin-desktop.sync.interval;
              } // {
                "sync.target" =
                  if (config.programs.joplin-desktop.sync.target != null)
                  then lib.strings.toInt (
                    # convert name of sync target into number that joplin expects
                    builtins.replaceStrings [ "none" "file-system" "onedrive" "nextcloud" "webdav" "dropbox" "s3" "joplin-server" "joplin-cloud" ]
                    [ "0" "2" "3" "5" "6" "7" "8" "9" "10" ]
                    config.programs.joplin-desktop.sync.target
                  )
                  else null;
              } // config.programs.joplin-desktop.extraConfig
            )
          );
        in lib.hm.dag.entryAfter [ "linkGeneration" ] ''
          # ensure that settings.json exists
          touch ${configPath}/settings.json
          # config has to be written to temporary variable because jq cannot edit files in place
          config="$(jq -s '.[0] + .[1]' ${configPath}/settings.json ${newConfig})"
          printf '%s\n' "$config" > ${configPath}/settings.json
        '';
    };
  };

  meta.maintainers = [ lib.maintainers.zorrobert ];
}