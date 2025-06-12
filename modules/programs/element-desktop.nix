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
    combineDefaultSettings = mkOption {
      type = lib.types.bool;
      default = false; # true would be better, but a breaking change
      description = ''
        Use element-web default configuration as a basis for settings and profiles.
      '';
    };
    combineSettingsProfiles = mkOption {
      type = lib.types.bool;
      default = false; # true would be better, but a breaking change
      description = ''
        Use settings as a basis for profiles.
      '';
    };
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
        For details about this behavior and available configuration options see:
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
        "--profile $NAME" flag. The same options apply here.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [ cfg.package ];
    home.file =
      let
        settings =
          if cfg.combineDefaultSettings then
            (pkgs.runCommandLocal "element-desktop-default.json"
              {
                nativeBuildInputs = [ pkgs.jq ];
              }
              ''
                jq -s '.[0] * $conf' "${cfg.package}/share/element/webapp/config.json" --argjson "conf" ${lib.escapeShellArg (builtins.toJSON cfg.settings)} > $out
              ''
            )
          else
            (formatter.generate "element-desktop-default.json" cfg.settings);
        defaultConfig =
          if (settings != { }) then
            {
              "${prefix}/Element/config.json".source = settings;
            }
          else
            { };
      in
      defaultConfig
      // (lib.mapAttrs' (
        name: value:
        let
          profile =
            if cfg.combineSettingsProfiles then
              (pkgs.runCommandLocal "element-desktop-${name}.json"
                {
                  nativeBuildInputs = [ pkgs.jq ];
                }
                ''
                  jq -s '.[0] * $conf' "${settings}" --argjson "conf" ${
                    lib.escapeShellArg (builtins.toJSON cfg.profiles."${name}")
                  } > $out
                ''
              )
            else
              (formatter.generate "element-desktop-${name}.json" cfg.profiles."${name}");
        in
        lib.nameValuePair "${prefix}/Element-${name}/config.json" {
          source = profile;
        }
      ) cfg.profiles);
  };
}
