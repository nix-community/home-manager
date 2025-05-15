{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.noti;
in
{
  meta.maintainers = [ ];

  options.programs.noti = {
    enable = lib.mkEnableOption "Noti";

    package = lib.mkPackageOption pkgs "noti" { nullable = true; };

    settings = lib.mkOption {
      type = with lib.types; attrsOf (attrsOf str);
      default = { };
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/noti/noti.yaml`.

        See
        {manpage}`noti.yaml(5)`.
        for the full list of options.
      '';
      example = lib.literalExpression ''
        {
          say = {
            voice = "Alex";
          };
          slack = {
            token = "1234567890abcdefg";
            channel = "@jaime";
          };
        }
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."noti/noti.yaml" = lib.mkIf (cfg.settings != { }) {
      text = lib.generators.toYAML { } cfg.settings;
    };
  };
}
