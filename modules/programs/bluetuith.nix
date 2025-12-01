{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.bluetuith;

  jsonFormat = pkgs.formats.json { };
in
{
  meta.maintainers = with lib.hm.maintainers; [
    poseidon-rises
  ];

  options.programs.bluetuith = {
    enable = lib.mkEnableOption "Bluetuith";

    package = lib.mkPackageOption pkgs "bluetuith" { nullable = true; };

    settings = lib.mkOption {
      type = jsonFormat.type;
      default = { };
      example = lib.literalExpression ''
        {
          adapter = "hci0";
          receive-dir = "/home/user/files";

          keybindings = {
            Menu = "Alt+m";
          };

          theme = {
            Adapter = "red";
          };
        }
      '';
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/bluetuith/bluetuith.conf`.

        See <https://bluetuith-org.github.io/bluetuith/Configuration.html> for
        details.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "programs.bluetuith" pkgs lib.platforms.linux)
    ];

    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."bluetuith/bluetuith.conf" = lib.mkIf (cfg.settings != { }) {
      source = jsonFormat.generate "bluetuith.conf" cfg.settings;
    };
  };
}
