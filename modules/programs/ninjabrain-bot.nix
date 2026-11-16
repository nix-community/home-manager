{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.ninjabrain-bot;
  xmlFormat = pkgs.formats.xml { };

  preferenceType = lib.types.oneOf [
    lib.types.bool
    lib.types.float
    lib.types.int
    lib.types.str
  ];

  toPreferenceString =
    value: if lib.isBool value || lib.isFloat value then builtins.toJSON value else toString value;

  preferencesXml = xmlFormat.generate "ninjabrain-bot-prefs.xml" {
    map = {
      "@MAP_XML_VERSION" = "1.0";
      entry = lib.mapAttrsToList (key: value: {
        "@key" = key;
        "@value" = toPreferenceString value;
      }) cfg.settings;
    };
  };

  javaPreferencesXml = pkgs.runCommandLocal "ninjabrain-bot-prefs.xml" { } ''
    {
      head -n 1 ${preferencesXml}
      printf '%s\n' '<!DOCTYPE map SYSTEM "http://java.sun.com/dtd/preferences.dtd">'
      tail -n +2 ${preferencesXml}
    } > "$out"
  '';
in
{
  meta.maintainers = [ lib.maintainers.nyxar77 ];

  options.programs.ninjabrain-bot = {
    enable = lib.mkEnableOption "Ninjabrain Bot";

    package = lib.mkPackageOption pkgs "ninjabrain-bot" { nullable = true; };

    settings = lib.mkOption {
      type = lib.types.attrsOf preferenceType;
      default = { };
      example = {
        always_on_top = true;
        language_v2 = "en-US";
        sigma = 0.05;
        theme = 1;
      };
      description = ''
        Ninjabrain Bot preferences written to
        {file}`$HOME/.java/.userPrefs/ninjabrainbot/prefs.xml`.

        Attribute names must use the preference keys understood by
        Ninjabrain Bot. Boolean, integer, floating-point, and string values are
        supported.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.optional (cfg.package != null) cfg.package;

    home.file.".java/.userPrefs/ninjabrainbot/prefs.xml" = lib.mkIf (cfg.settings != { }) {
      force = true;
      source = javaPreferencesXml;
    };
  };
}
