{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.yopass;
in
{
  meta.maintainers = [ lib.maintainers.fraggerfox ];

  options.programs.yopass = {
    enable = lib.mkEnableOption "Yopass, a tool for sharing secrets and files securely";

    package = lib.mkPackageOption pkgs "yopass" { nullable = true; };

    settings = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.oneOf [
          lib.types.bool
          lib.types.int
          lib.types.str
        ]
      );
      default = { };
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/yopass/defaults.yml`.

        See the [CLI documentation](https://yopass.se/docs/cli) for the
        full list of available settings (`api`, `api-token`, `url`,
        `one-time`, `expiration`).
      '';
      example = {
        api = "https://api.example.com";
        url = "https://example.com";
        "one-time" = false;
        expiration = "1d";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."yopass/defaults.yml" = lib.mkIf (cfg.settings != { }) {
      text = lib.generators.toYAML { } cfg.settings;
    };
  };
}
