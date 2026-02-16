{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.programs.infat;
  tomlFormat = pkgs.formats.toml { };

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
        type = tomlFormat.type;
        default = { };
        example = lib.literalExpression ''
          {
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
          }
        '';
        description = ''
          Configuration written to
          {file}`$XDG_CONFIG_HOME/infat/config.toml`.
        '';
      };
      autoActivate = lib.mkEnableOption "auto-activate infat" // {
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
    };
  };
  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "programs.infat" pkgs lib.platforms.darwin)
    ];
    home = {
      packages = lib.mkIf (cfg.package != null) [ cfg.package ];
      file.${configFile} = lib.mkIf (cfg.settings != { }) {
        source = tomlFormat.generate "infat-settings.toml" cfg.settings;
      };
      activation = lib.mkIf (cfg.settings != { } && cfg.package != null && cfg.autoActivate) {
        infat = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          run ${lib.getExe cfg.package} --config "${configFile}" $VERBOSE_ARG
        '';
      };
    };
  };
}
