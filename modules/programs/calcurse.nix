{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.calcurse;

  iniFormat = pkgs.formats.ini { };

  caldavConfigFile = iniFormat.generate "config" cfg.caldav.settings;

  formatLine = o: n: v:
    let
      formatValue = v:
        if builtins.isNull v then
          "None"
        else if builtins.isBool v then
          (if v then "yes" else "no")
        else if builtins.isString v then
          "${v}"
        else if builtins.isList v then
          "${concatStringsSep " " (map formatValue v)}"
        else
          builtins.toString v;
    in if o == "" then
      "${n}  ${formatValue v}"
    else
      "${o}${n}=${formatValue v}";

in {
  options.programs.calcurse = {
    enable = mkEnableOption
      "calcurse - a text-based calendar and scheduling application";

    package = mkOption {
      type = types.package;
      default = pkgs.calcurse;
      defaultText = "pkgs.calcurse";
      description =
        "Package containing the <command>calcurse</command> executable.";
    };

    hooks = {
      preLoad = mkOption {
        type = types.lines;
        default = "";
        example = literalExpression ''
          #!/bin/sh
          notify-send "Loaded calendar"
        '';
        description = "Script ran before loading Calcurse calendar.";
      };
      postLoad = mkOption {
        type = types.lines;
        default = "";
        example = literalExpression ''
          #!/bin/sh
          notify-send "Loaded calendar"
        '';
        description = "Script ran after loading Calcurse calendar.";
      };
      preSave = mkOption {
        type = types.lines;
        default = "";
        example = literalExpression ''
          #!/bin/sh
          notify-send "Saved calendar"
        '';
        description = "Script ran before saving Calcurse calendar.";
      };
      postSave = mkOption {
        type = types.lines;
        default = "";
        example = literalExpression ''
          #!/bin/sh
          notify-send "Saved calendar"
        '';
        description = "Script ran after saving Calcurse calendar.";
      };
    };

    caldav.settings = mkOption {
      type = iniFormat.type;
      default = { };
      description = ''
        calcurse-caldav plugin settings.
      '';
      example = literalExpression ''
        {
          settings = {
            General = {
              Binary = "calcurse";
              Hostname = "example.com";
              Path = "/";
              InsecureSSL = "No";
              HTTPS = "Yes";
              SyncFilter = "cal,todo";
              DryRun = "No";
              Verbose = "Yes";
            };
            Auth = {
              Username = "username";
              Password = "password";
            };
          };
        };
      '';
    };

    settings = {
      general = mkOption {
        type = types.attrsOf types.anything;
        default = { };
        description = ''
          Calcurse 'general' settings.
        '';
        example = literalExpression ''
          {
            autogc = false;
            autosave = true;
          };
        '';
      };
      appearance = mkOption {
        type = types.attrsOf types.anything;
        default = { };
        description = ''
          Calcurse 'appearance' settings.
        '';
        example = literalExpression ''
          {
            calendarview = "monthly";
            compactpanels = false;
          };
        '';
      };
      format = mkOption {
        type = types.attrsOf types.anything;
        default = { };
        description = ''
          Calcurse 'format' settings.
        '';
        example = literalExpression ''
          {
            notifydate = "%a %F";
            notifytime = "%T";
          };
        '';
      };
    };

    keys = mkOption {
      type = types.attrsOf types.anything;
      default = { };
      description = ''
        Calcurse keybinds.
      '';
      example = literalExpression ''
        {
          generic-cancel = "ESC";
          generic-select = "SPC";
        };
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "programs.calcurse" pkgs
        lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    # main `calcurse` config files
    xdg.configFile = {
      "calcurse/conf" = {
        text = concatStringsSep "\n"
          (mapAttrsToList (formatLine "appearance.") cfg.settings.appearance
            ++ mapAttrsToList (formatLine "general.") cfg.settings.general
            ++ mapAttrsToList (formatLine "format.") cfg.settings.format);
      };
      "calcurse/keys" = mkIf (cfg.keys != { }) {
        text = concatStringsSep "\n" (mapAttrsToList (formatLine "") cfg.keys);
      };
    };

    # `calcurse-caldav` config file
    xdg.configFile."calcurse/caldav/config" =
      mkIf (cfg.caldav.settings != { }) { source = caldavConfigFile; };

    # `calcurse` hooks
    xdg.configFile = {
      "calcurse/hooks/pre-load" = mkIf (cfg.hooks.preLoad != "") {
        text = cfg.hooks.preLoad;
        executable = true;
      };
      "calcurse/hooks/post-load" = mkIf (cfg.hooks.postLoad != "") {
        text = cfg.hooks.postLoad;
        executable = true;
      };
      "calcurse/hooks/pre-save" = mkIf (cfg.hooks.preSave != "") {
        text = cfg.hooks.preSave;
        executable = true;
      };
      "calcurse/hooks/post-save" = mkIf (cfg.hooks.postSave != "") {
        text = cfg.hooks.postSave;
        executable = true;
      };
    };
  };
}
