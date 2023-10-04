{ config, lib, pkgs, ... }:

let
  cfg = config.programs.openstackclient;
  yamlFormat = pkgs.formats.yaml { };
in {
  meta.maintainers = [ lib.hm.maintainers.tensor5 ];

  options.programs.openstackclient = {
    enable = lib.mkEnableOption "OpenStack command-line client";

    package = lib.mkPackageOption pkgs "openstackclient" { };

    clouds = lib.mkOption {
      type = lib.types.submodule { freeformType = yamlFormat.type; };
      default = { };
      example = lib.literalExpression ''
        {
          my-infra = {
            cloud = "example-cloud";
            auth = {
              project_id = "0123456789abcdef0123456789abcdef";
              username = "openstack";
            };
            region_name = "XXX";
            interface = "internal";
          };
        }
      '';
      description = ''
        Configuration needed to connect to one or more clouds.

        Do not include passwords here as they will be publicly readable in the Nix store.
        Configuration written to {file}`$XDG_CONFIG_HOME/openstack/clouds.yaml`.
        See <https://docs.openstack.org/python-openstackclient/latest/configuration/index.html#clouds-yaml>.
      '';
    };

    publicClouds = lib.mkOption {
      type = lib.types.submodule { freeformType = yamlFormat.type; };
      default = { };
      example = lib.literalExpression ''
        {
          example-cloud = {
            auth = {
              auth_url = "https://identity.cloud.example.com/v2.0";
            };
          };
        };
      '';
      description = ''
        Public information about clouds.

        Configuration written to {file}`$XDG_CONFIG_HOME/openstack/clouds-public.yaml`.
        See <https://docs.openstack.org/python-openstackclient/latest/configuration/index.html#clouds-public-yaml>.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."openstack/clouds.yaml".source = yamlFormat.generate
      "openstackclient-clouds-yaml-${config.home.username}" {
        clouds = cfg.clouds;
      };

    xdg.configFile."openstack/clouds-public.yaml".source = yamlFormat.generate
      "openstackclient-clouds-public-yaml-${config.home.username}" {
        public-clouds = cfg.publicClouds;
      };
  };
}
