{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.wrtag;

  # flagconf uses "key value" spacing and duplicate keys for lists
  flagconfFormat = pkgs.formats.keyValue {
    listsAsDuplicateKeys = true;
    mkKeyValue = lib.generators.mkKeyValueDefault { } " ";
  };

in
{
  meta.maintainers = [ lib.maintainers.philocalyst ];

  options.programs.wrtag = {
    enable = lib.mkEnableOption "wrtag, a music tagging and organisation tool based on MusicBrainz";

    package = lib.mkPackageOption pkgs "wrtag" { nullable = true; };

    settings = lib.mkOption {
      type = flagconfFormat.type;
      default = { };
      description = ''
        Configuration written in flagconf format (`key value` per line).

        Stackable options such as `addon`, `keep-file`, and `notification-uri`
        accept a list; each element becomes its own line with the same key.

        See <https://github.com/sentriz/wrtag#global-configuration> for
        available options.

        And <https://github.com/sentriz/wrtag#config-file> for default locations
      '';
      example = lib.literalExpression ''
        {
          path-format = "/music/{{ artists .Release.Artists | join \"; \" | safepath }}/({{ .Release.ReleaseGroup.FirstReleaseDate.Year }}) {{ .Release.Title | safepath }}/{{ pad0 2 .Track.Position }} {{ .Track.Title | safepath }}{{ .Ext }}";
          addon = [ "replaygain" "lyrics lrclib genius" ];
          log-level = "debug";
          cover-upgrade = true;
        }
      '';
    };
  };

  config = lib.mkIf cfg.enable (
    let
      useXdg = !pkgs.stdenv.hostPlatform.isDarwin || config.home.preferXdgDirectories;
      hasSettings = cfg.settings != { };
      configFile = flagconfFormat.generate "wrtag-config" cfg.settings;
    in
    {
      home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

      xdg.configFile."wrtag/config" = lib.mkIf (hasSettings && useXdg) {
        source = configFile;
      };

      home.file."Library/Application Support/wrtag/config" = lib.mkIf (hasSettings && !useXdg) {
        source = configFile;
      };
    }
  );
}
