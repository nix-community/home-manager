{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.polybar;

  eitherStrBoolIntList = with types; either str (either bool (either int (listOf str)));

  toPolybarIni = generators.toINI {
    mkKeyValue = key: value:
      let
        quoted = v:
          if hasPrefix " " v || hasSuffix " " v
          then ''"${v}"''
          else v;

        value' =
          if isBool value then (if value then "true" else "false")
          else if (isString value && key != "include-file") then quoted value
          else toString value;
      in
        "${key}=${value'}";
  };

  configFile = pkgs.writeText "polybar.conf"
    (toPolybarIni cfg.config + "\n" + cfg.extraConfig);

in

{
  options = {
    services.polybar = {
      enable = mkEnableOption "Polybar status bar";

      package = mkOption {
        type = types.package;
        default = pkgs.polybar;
        defaultText = literalExample "pkgs.polybar";
        description = "Polybar package to install.";
        example =  literalExample ''
          pkgs.polybar.override {
            i3GapsSupport = true;
            alsaSupport = true;
            iwSupport = true;
            githubSupport = true;
          }
        '';
      };

      config = mkOption {
        type = types.coercedTo
          types.path
          (p: { "section/base" = { include-file = "${p}"; }; })
          (types.attrsOf (types.attrsOf eitherStrBoolIntList));
        description = ''
          Polybar configuration. Can be either path to a file, or set of attributes
          that will be used to create the final configuration.
        '';
        default = {};
        example = literalExample ''
          {
            "bar/top" = {
              monitor = "\''${env:MONITOR:eDP1}";
              width = "100%";
              height = "3%";
              radius = 0;
              modules-center = "date";
            };

            "module/date" = {
              type = "internal/date";
              internal = 5;
              date = "%d.%m.%y";
              time = "%H:%M";
              label = "%time%  %date%";
            };
          }
        '';
      };

      extraConfig = mkOption {
        type = types.lines;
        description = "Additional configuration to add.";
        default = "";
        example = ''
          [module/date]
          type = internal/date
          interval = 5
          date = "%d.%m.%y"
          time = %H:%M
          format-prefix-foreground = \''${colors.foreground-alt}
          label = %time%  %date%
        '';
      };

      script = mkOption {
        type = types.lines;
        description = ''
          This script will be used to start the polybars.
          Set all necessary environment variables here and start all bars.
          It can be assumed that <command>polybar</command> executable is in the <envar>PATH</envar>.

          Note, this script must start all bars in the background and then terminate.
        '';
        example = "polybar bar &";
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];
    xdg.configFile."polybar/config".source = configFile;

    systemd.user.services.polybar = {
      Unit = {
        Description = "Polybar status bar";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
        X-Restart-Triggers = [
          "${config.xdg.configFile."polybar/config".source}"
        ];
      };

      Service = {
        Type = "forking";
        Environment = "PATH=${cfg.package}/bin:/run/wrappers/bin";
        ExecStart =
          let
            scriptPkg = pkgs.writeShellScriptBin "polybar-start" cfg.script;
          in
            "${scriptPkg}/bin/polybar-start";
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };

}
