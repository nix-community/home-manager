{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.darkman;

  yamlFormat = pkgs.formats.yaml { };

  scriptsOptionType = kind:
    mkOption {
      type = types.attrsOf (types.oneOf [ types.path types.lines ]);
      default = { };
      example = literalExpression ''
        {
          gtk-theme = '''
            ''${pkgs.dconf}/bin/dconf write \
                /org/gnome/desktop/interface/color-scheme "'prefer-${kind}'"
          ''';
          my-python-script = pkgs.writers.writePython3 "my-python-script" { } '''
            print('Do something!')
          ''';
        }
      '';
      description = ''
        Scripts to run when switching to "${kind} mode".

        Multiline strings are interpreted as Bash shell scripts and a shebang is
        not required.
      '';
    };

  generateScripts = folder:
    mapAttrs' (k: v: {
      name = "${folder}/${k}";
      value = {
        source = if builtins.isPath v || isDerivation v then
          v
        else
          pkgs.writeShellScript (hm.strings.storeFileName k) v;
      };
    });
in {
  meta.maintainers = [ maintainers.xlambein ];

  options.services.darkman = {
    enable = mkEnableOption ''
      darkman, a tool that automatically switches dark-mode on and off based on
      the time of the day'';

    package = mkPackageOption pkgs "darkman" { };

    settings = mkOption {
      type = types.submodule { freeformType = yamlFormat.type; };
      default = { };
      example = literalExpression ''
        {
          lat = 52.3;
          lng = 4.8;
          usegeoclue = true;
        }
      '';
      description = ''
        Settings for the {command}`darkman` command. See
        <https://darkman.whynothugo.nl/#CONFIGURATION> for details.
      '';
    };

    darkModeScripts = scriptsOptionType "dark";

    lightModeScripts = scriptsOptionType "light";
  };

  config = mkIf cfg.enable {
    assertions = [
      (hm.assertions.assertPlatform "services.darkman" pkgs platforms.linux)
    ];

    home.packages = [ cfg.package ];

    xdg.configFile = {
      "darkman/config.yaml" = mkIf (cfg.settings != { }) {
        source = yamlFormat.generate "darkman-config.yaml" cfg.settings;
      };
    };

    xdg.dataFile = mkMerge [
      (mkIf (cfg.darkModeScripts != { })
        (generateScripts "dark-mode.d" cfg.darkModeScripts))
      (mkIf (cfg.lightModeScripts != { })
        (generateScripts "light-mode.d" cfg.lightModeScripts))
    ];

    systemd.user.services.darkman = {
      Unit = {
        Description = "Darkman system service";
        Documentation = "man:darkman(1)";
        PartOf = [ "graphical-session.target" ];
        BindsTo = [ "graphical-session.target" ];
        X-Restart-Triggers = mkIf (cfg.settings != { })
          [ "${config.xdg.configFile."darkman/config.yaml".source}" ];
      };

      Service = {
        Type = "dbus";
        BusName = "nl.whynothugo.darkman";
        ExecStart = "${getExe cfg.package} run";
        Restart = "on-failure";
        TimeoutStopSec = 15;
        Slice = "background.slice";
      };

      Install.WantedBy = mkDefault [ "graphical-session.target" ];
    };
  };
}
