{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib)
    types
    mkIf
    mkEnableOption
    mkPackageOption
    mkOption
    ;

  cfg = config.programs.element-desktop;

  formatter = pkgs.formats.json { };

  prefix =
    if pkgs.stdenv.hostPlatform.isDarwin then "Library/Application Support" else config.xdg.configHome;
in
{
  meta.maintainers = with lib.hm.maintainers; [ aguirre-matteo ];

  options.programs.element-desktop = {
    enable = mkEnableOption "element-desktop";
    package = mkPackageOption pkgs "element-desktop" { nullable = true; };
    settings = mkOption {
      type = formatter.type;
      default = { };
      example = ''
        {
          default_server_config = {
            "m.homeserver" = {
                base_url = "https://matrix-client.matrix.org";
                server_name = "matrix.org";
            };
            "m.identity_server" = {
                base_url = "https://vector.im";
            };
          };
          disable_custom_urls = false;
          disable_guests = false;
          disable_login_language_selector = false;
          disable_3pid_login = false;
          force_verification = false;
          brand = "Element";
          integrations_ui_url = "https://scalar.vector.im/";
          integrations_rest_url = "https://scalar.vector.im/api";
        }
      '';
      description = ''
        Configuration settings for Element's default profiles.
        WARNING: Element doesn't combine this config with the defaults,
        so make sure to configure most options. For details about this
        behavior and available configuration options see:
        <https://github.com/element-hq/element-web/blob/develop/docs/config.md>
      '';
    };
    profiles = mkOption {
      type = types.attrsOf formatter.type;
      default = { };
      example = ''
        {
          work = {
            default_server_config = {
              "m.homeserver" = {
                  base_url = "https://matrix-client.matrix.org";
                  server_name = "matrix.org";
              };
              "m.identity_server" = {
                  base_url = "https://vector.im";
              };
            };
          };
          home = {
            disable_custom_urls = false;
            disable_guests = false;
            disable_login_language_selector = false;
            disable_3pid_login = false;
          };
          other = {
            force_verification = false;
            brand = "Element";
            integrations_ui_url = "https://scalar.vector.im/";
            integrations_rest_url = "https://scalar.vector.im/api";
          };
        }
      '';
      description = ''
        Extra profiles for Element. Those can be accessed using the
        "--profile $NAME" flag. The same warning and options apply
        here.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [ cfg.package ];
    home.file =
      let
        defaultConfig =
          if (cfg.settings != { }) then
            {
              "${prefix}/Element/config.json".source = (
                formatter.generate "element-desktop-default" cfg.settings
              );
            }
          else
            { };
      in
      defaultConfig
      // (lib.mapAttrs' (
        name: value:
        lib.nameValuePair "${prefix}/Element-${name}/config.json" {
          source = (formatter.generate "element-desktop-${name}" cfg.profiles."${name}");
        }
      ) cfg.profiles);
  };
}
