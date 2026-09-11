{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.openstackclient;
  yamlFormat = pkgs.formats.yaml { };
  # Legacy cloud mappings may be defined as module functions.
  settingsType = lib.types.attrsOf (
    lib.types.either yamlFormat.type (lib.types.submodule { freeformType = yamlFormat.type; })
  );
in
{
  imports =
    lib.hm.deprecations.mkSettingsRenamedOptionModules
      [ "programs" "openstackclient" ]
      [ "programs" "openstackclient" ]
      { }
      [
        {
          old = "clouds";
          new = [
            "cloudsSettings"
            "clouds"
          ];
        }
        {
          old = "publicClouds";
          new = [
            "cloudsPublicSettings"
            "public-clouds"
          ];
        }
      ];

  meta.maintainers = [ lib.maintainers.tensor5 ];

  options.programs.openstackclient = {
    enable = lib.mkEnableOption "OpenStack command-line client";

    package = lib.mkPackageOption pkgs "openstackclient" { nullable = true; };

    cloudsSettings = lib.mkOption {
      type = settingsType;
      default = { };
      example = {
        clouds.my-infra = {
          cloud = "example-cloud";
          auth = {
            project_id = "0123456789abcdef0123456789abcdef";
            username = "openstack";
          };
          region_name = "XXX";
          interface = "internal";
        };
      };
      description = ''
        Whole-file configuration for the OpenStack client, including `clouds`,
        `cache`, and `client` settings.

        Do not include passwords, tokens, or application credential secrets
        here, as they will be publicly readable in the Nix store. Use the
        runtime environment or an externally managed {file}`secure.yaml` file.
        Configuration written to {file}`$XDG_CONFIG_HOME/openstack/clouds.yaml`.
        See <https://docs.openstack.org/python-openstackclient/latest/configuration/index.html#clouds-yaml>.
      '';
    };

    cloudsPublicSettings = lib.mkOption {
      type = settingsType;
      default = { };
      example = lib.literalExpression ''
        {
          public-clouds.example-cloud = {
            auth = {
              auth_url = "https://identity.cloud.example.com/v2.0";
            };
          };
        };
      '';
      description = ''
        Whole-file public cloud configuration, including the `public-clouds`
        mapping.

        Configuration written to {file}`$XDG_CONFIG_HOME/openstack/clouds-public.yaml`.
        See <https://docs.openstack.org/python-openstackclient/latest/configuration/index.html#clouds-public-yaml>.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile = {
      "openstack/clouds.yaml" = lib.mkIf (cfg.cloudsSettings != { }) {
        source = yamlFormat.generate "openstackclient-clouds-yaml-${config.home.username}" cfg.cloudsSettings;
      };
      "openstack/clouds-public.yaml" = lib.mkIf (cfg.cloudsPublicSettings != { }) {
        source = yamlFormat.generate "openstackclient-clouds-public-yaml-${config.home.username}" cfg.cloudsPublicSettings;
      };
    };
  };
}
