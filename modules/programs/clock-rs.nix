{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.clock-rs;
  tomlFormat = pkgs.formats.toml { };
in
{
  meta.maintainers = with lib.maintainers; [ oughie ];

  options.programs.clock-rs = {
    enable = lib.mkEnableOption "clock-rs";

    package = lib.mkPackageOption pkgs "clock-rs" { nullable = true; };

    settings = lib.mkOption {
      type = tomlFormat.type;
      default = { };
      description = "The configuration file to be used for clock-rs";
      example = lib.literalExpression ''
        general = {
          color = "magenta";
          interval = 250;
          blink = true;
          bold = true;
        };

        position = {
          horizontal = "start";
          vertical = "end";
        };

        date = {
          fmt = "%A, %B %d, %Y";
          use_12h = true;
          utc = true;
          hide_seconds = true;
        };
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home =
      let
        configDir =
          if pkgs.stdenv.hostPlatform.isDarwin then "Library/Application Support" else config.xdg.configHome;
      in
      {
        packages = lib.mkIf (cfg.package != null) [ cfg.package ];

        file."${configDir}/clock-rs/conf.toml" = lib.mkIf (cfg.settings != { }) {
          source = tomlFormat.generate "clock-rs-config" cfg.settings;
        };
      };
  };

}
