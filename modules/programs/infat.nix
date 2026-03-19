{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.programs.infat;
  tomlFormat = pkgs.formats.toml { };
  mkCli = lib.cli.toCommandLineShellGNU { };

  configDir =
    if config.xdg.enable then
      config.xdg.configHome
    else
      "${config.home.homeDirectory}/Library/Application Support";

  configFile = "${configDir}/infat/config.toml";
in
{
  meta.maintainers = with lib.maintainers; [
    mirkolenz
  ];

  options = {
    programs.infat = {
      enable = lib.mkEnableOption "infat";
      package = lib.mkPackageOption pkgs "infat" { nullable = true; };
      settings = lib.mkOption {
        inherit (tomlFormat) type;
        default = { };
        example = {
          extensions = {
            md = "TextEdit";
            html = "Safari";
            pdf = "Preview";
          };
          schemes = {
            mailto = "Mail";
            web = "Safari";
          };
          types = {
            plain-text = "VSCode";
          };
        };
        description = ''
          Configuration written to
          {file}`$XDG_CONFIG_HOME/infat/config.toml`.
        '';
      };
      autoActivate = lib.mkOption {
        type =
          lib.types.coercedTo lib.types.bool
            (enable: {
              inherit enable;
              _legacyBoolean = true;
            })
            (
              lib.types.submodule {
                options = {
                  _legacyBoolean = lib.mkOption {
                    type = lib.types.bool;
                    default = false;
                    visible = false;
                  };
                  enable = lib.mkEnableOption "auto-activate infat" // {
                    default = true;
                    example = false;
                    description = ''
                      Automatically activate infat on startup.
                      This is useful if you want to use infat as a
                      default application handler for certain file types.
                      If you don't want this, set this to false.
                      This option is only effective if `settings` is set.
                    '';
                  };
                  extraArgs = lib.mkOption {
                    type =
                      with lib.types;
                      attrsOf (oneOf [
                        str
                        bool
                      ]);
                    default = {
                      robust = true;
                    };
                    example = {
                      quiet = true;
                    };
                    description = ''
                      Additional arguments to pass when auto-activating infat.
                      This can be used to customize the behavior of infat when
                      it is auto-activated on startup. Call `infat --help`
                      for more information on available arguments.
                      If {option}`programs.infat.settings` is set,
                      `config` will be added automatically.
                      Otherwise you can set `config` to point
                      to a custom configuration file.
                    '';
                  };
                };
              }
            );
        default = { };
        example = {
          enable = true;
          extraArgs = {
            quiet = true;
          };
        };
        description = ''
          Auto-activation settings for infat.

          For backwards compatibility, this option also accepts a boolean.
          Boolean values are deprecated; use
          {option}`programs.infat.autoActivate.enable` instead.
        '';
      };
    };
  };
  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "programs.infat" pkgs lib.platforms.darwin)
    ];
    warnings = lib.optional cfg.autoActivate._legacyBoolean ''
      Using `programs.infat.autoActivate` as a Boolean is deprecated and will be
      removed in a future release. Please use `programs.infat.autoActivate.enable`
      instead.
    '';
    programs.infat.autoActivate.extraArgs = lib.mkIf (cfg.settings != { }) {
      config = configFile;
    };
    home = {
      packages = lib.mkIf (cfg.package != null) [ cfg.package ];
      file.${configFile} = lib.mkIf (cfg.settings != { }) {
        source = tomlFormat.generate "infat-settings.toml" cfg.settings;
      };
      activation =
        lib.mkIf (cfg.package != null && cfg.autoActivate.enable && cfg.autoActivate.extraArgs ? config)
          {
            infat = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
              run ${lib.getExe cfg.package} ${mkCli cfg.autoActivate.extraArgs} $VERBOSE_ARG
            '';
          };
    };
  };
}
