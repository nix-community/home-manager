{ config, lib, pkgs, ... }:
let
  cfg = config.programs.joplin-desktop;
  # config path is the same for linux and mac
  configPath = (config.home.homeDirectory + "/.config/joplin-desktop");
in {
  options.programs.joplin-desktop = {
    enable = lib.mkEnableOption "joplin-desktop";
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.joplin-desktop;
      defaultText = lib.literalExpression "pkgs.joplin-desktop";
      description = "Package containing the joplin-desktop program.";
    };
    extraConfig = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = ''
        Use this to add options to the Joplin config file. Settings are written in JSON, so "sync.interval":600 is written as "sync.interval" = 600'';
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
        type = lib.types.nullOr lib.types.int;
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

    # write new config to temporary read-only file
    home.file."home-manager-settings.json" = {
      target = (configPath + "/home-manager-settings.json");
      text = builtins.toJSON ((
        # check if config file exists
        if builtins.pathExists (configPath + "/settings.json") then
          let
            currentConfig = builtins.readFile (configPath + "/settings.json");
            # check if file is not empty
          in if ((currentConfig == "") || (currentConfig == "{}")) then
            { }
          else
            builtins.fromJSON currentConfig
        else
          { }
      ) 
      # filter out null values and empty strings before merging with current config
      # this is so that an undefined option does not override the current config
      // lib.attrsets.filterAttrs (n: v: (v != null) && (v != "")) ({
        # TODO: find a better way to convert nix attribute names to strings:
        # sync.interval = ... -> "sync.interval" = ...
        "editor" = config.programs.joplin-desktop.general.editor;
        "sync.interval" = config.programs.joplin-desktop.sync.interval;
      } // {
        "sync.target" =
          if (config.programs.joplin-desktop.sync.target != null) then
            lib.strings.toInt (
              # convert name of sync target into number that joplin expects
              builtins.replaceStrings [
                "none"
                "file-system"
                "onedrive"
                "nextcloud"
                "webdav"
                "dropbox"
                "s3"
                "joplin-server"
                "joplin-cloud"
              ] [ "0" "2" "3" "5" "6" "7" "8" "9" "10" ]
              config.programs.joplin-desktop.sync.target)
          else
            null;
      } // config.programs.joplin-desktop.extraConfig));
    };

    # copy the contents of the temporary file to the real config file
    home.activation = {
      hm-activate-joplin-desktop-config =
        lib.hm.dag.entryAfter [ "linkGeneration" ] ''
          cat ${configPath}/home-manager-settings.json > ${configPath}/settings.json
        '';
    };
  };
  meta.maintainers = [ lib.maintainers.zorrobert ];
}