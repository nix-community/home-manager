{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf types;

  cfg = config.services.darkman;

  yamlFormat = pkgs.formats.yaml { };

  scriptsOptionType =
    kind:
    lib.mkOption {
      type = types.attrsOf (
        types.oneOf [
          types.path
          types.lines
        ]
      );
      default = { };
      example = lib.literalExpression ''
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

  generateScripts =
    folder:
    lib.mapAttrs' (
      k: v: {
        name = "${folder}/${k}";
        value = {
          source =
            if builtins.isPath v || lib.isDerivation v then
              v
            else
              pkgs.writeShellScript (lib.hm.strings.storeFileName k) v;
        };
      }
    );
in
{
  meta.maintainers = [ lib.maintainers.xlambein ];

  options.services.darkman = {
    enable = lib.mkEnableOption ''
      darkman, a tool that automatically switches dark-mode on and off based on
      the time of the day'';

    package = lib.mkPackageOption pkgs "darkman" { nullable = true; };

    settings = lib.mkOption {
      type = types.submodule { freeformType = yamlFormat.type; };
      default = { };
      example = lib.literalExpression ''
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
      (lib.hm.assertions.assertPlatform "services.darkman" pkgs lib.platforms.linux)
    ];

    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile = {
      "darkman/config.yaml" = mkIf (cfg.settings != { }) {
        source = yamlFormat.generate "darkman-config.yaml" cfg.settings;
      };
    };

    xdg.dataFile = lib.mkMerge [
      (mkIf (cfg.darkModeScripts != { }) (generateScripts "dark-mode.d" cfg.darkModeScripts))
      (mkIf (cfg.lightModeScripts != { }) (generateScripts "light-mode.d" cfg.lightModeScripts))
    ];

    systemd.user.services.darkman = lib.mkIf (cfg.package != null) {
      Unit = {
        Description = "Darkman system service";
        Documentation = "man:darkman(1)";
        PartOf = [ "graphical-session.target" ];
        BindsTo = [ "graphical-session.target" ];
        X-Restart-Triggers = mkIf (cfg.settings != { }) [
          "${config.xdg.configFile."darkman/config.yaml".source}"
        ];
      };

      Service = {
        Type = "dbus";
        BusName = "nl.whynothugo.darkman";
        ExecStart = "${lib.getExe cfg.package} run";
        Restart = "on-failure";
        TimeoutStopSec = 15;
        Slice = "background.slice";
      };

      Install.WantedBy = lib.mkDefault [ "graphical-session.target" ];
    };
  };
}
