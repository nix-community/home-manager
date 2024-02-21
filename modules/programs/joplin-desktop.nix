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
        type = lib.types.enum [ null "none" "file-system" "onedrive" "nextcloud" "webdav" "dropbox" "s3" "joplin-server" "joplin-cloud" ];
        default = null;
        description = "What is the type of sync target.";
        example = "dropbox";
      };

      interval = lib.mkOption {
        type = lib.types.enum [ null "disabled" "5m" "10m" "30m" "1h" "12h" "1d" ];
        default = null;
        description = ''
          Set the Synchronisation interval. The following values can be used: "disabled" "5m" "10m" "30m" "1h" "12h" "1d"
        '';
        example = "10m";
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

                "sync.target" = {
                  "none"          = 0;
                  "file-system"   = 2;
                  "onedrive"      = 3;
                  "nextcloud"     = 5;
                  "webdav"        = 6;
                  "dropbox"       = 7;
                  "s3"            = 8;
                  "joplin-server" = 9;
                  "joplin-cloud"  = 10;
                }.${config.programs.joplin-desktop.sync.target} or null;

                "sync.interval" = {
                  "disabled"  =     0;
                  "5m"        =   300;
                  "10m"       =   600;
                  "30m"       =  1800;
                  "1h"        =  3600;
                  "12h"       = 43200;
                  "1d"        = 86400;
                }.${config.programs.joplin-desktop.sync.interval} or null;
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
