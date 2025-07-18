{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.iamb;
  tomlFormat = pkgs.formats.toml { };
in
{
  options.programs.iamb = {
    enable = lib.mkEnableOption "iamb";

    package = lib.mkPackageOption pkgs "iamb" { nullable = true; };

    settings = lib.mkOption {
      type = tomlFormat.type;
      default = { };
      example = lib.literalExpression ''
        {
          default_profile = "personal";
          settings = {
            notifications.enabled = true;
            image_preview.protocol = {
              type = "kitty";
              size = {
                height = 10;
                width = 66;
              };
            };
          };
        }
      '';
      description = ''
        Configuration written to

        {file}`$XDG_CONFIG_HOME/iamb/config.toml` on Linux
        {file}`$HOME/Library/Application Support/iamb/config.toml` on macOS

        See <https://iamb.chat/configure.html> for the full list
        of options.
      '';
    };

  };

  config =
    let
      configFile = tomlFormat.generate "iamb-config" cfg.settings;
    in
    lib.mkIf cfg.enable {
      home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

      xdg.configFile."iamb/config.toml" =
        lib.mkIf (cfg.settings != { } && pkgs.stdenv.isDarwin == false)
          {
            source = configFile;
          };

      home.file."Library/Application Support/iamb/config.toml" =
        lib.mkIf (cfg.settings != { } && pkgs.stdenv.isDarwin == true)
          {
            source = configFile;
          };
    };
}
