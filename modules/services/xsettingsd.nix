{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.xsettingsd;

  renderSettings = settings:
    concatStrings (mapAttrsToList renderSetting settings);

  renderSetting = key: value: ''
    ${key} ${renderValue value}
  '';

  renderValue = value:
    {
      int = toString value;
      bool = if value then "1" else "0";
      string = ''"${value}"'';
    }.${builtins.typeOf value};

in {
  meta.maintainers = [ maintainers.imalison ];

  options = {
    services.xsettingsd = {
      enable = mkEnableOption "xsettingsd";

      package = mkOption {
        type = types.package;
        default = pkgs.xsettingsd;
        defaultText = literalExpression "pkgs.xsettingsd";
        description = ''
          Package containing the <command>xsettingsd</command> program.
        '';
      };

      settings = mkOption {
        type = with types; attrsOf (oneOf [ bool int str ]);
        default = { };
        example = literalExpression ''
          {
            "Net/ThemeName" = "Numix";
            "Xft/Antialias" = true;
            "Xft/Hinting" = true;
            "Xft/RGBA" = "rgb";
          }
        '';
        description = ''
          Xsettingsd options for configuration file. See
          <link xlink:href="https://github.com/derat/xsettingsd/wiki/Settings"/>
          for documentation on these values.
        '';
      };

      configFile = mkOption {
        type = types.nullOr types.package;
        internal = true;
        readOnly = true;
        default = if cfg.settings == { } then
          null
        else
          pkgs.writeText "xsettingsd.conf" (renderSettings cfg.settings);
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.xsettingsd" pkgs
        lib.platforms.linux)
    ];

    systemd.user.services.xsettingsd = {
      Unit = {
        Description = "xsettingsd";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Install.WantedBy = [ "graphical-session.target" ];

      Service = {
        Environment = "PATH=${config.home.profileDirectory}/bin";
        ExecStart = "${cfg.package}/bin/xsettingsd"
          + optionalString (cfg.configFile != null)
          " -c ${escapeShellArg cfg.configFile}";
        Restart = "on-abort";
      };
    };
  };
}
