{ lib, ... }:
{
  imports = [
    { programs.openstackclient.cloudsSettings.cache.expiration_time = 300; }
  ];

  programs.openstackclient = {
    enable = true;
    package = null;
    cloudsSettings.cache.auth = true;
    cloudsSettings.client.force_ipv4 = true;
    cloudsSettings.custom = {
      credentials = [
        "application"
        42
        null
      ];
      enabled = true;
      optional = null;
      retries = 3;
      timeout = 1.5;
      "yaml-1.1-string" = "yes";
    };
    cloudsSettings.clouds = {
      my-infra = {
        cloud = "example-cloud";
        auth = {
          project_id = "0123456789abcdef0123456789abcdef";
          username = "openstack";
        };
        region_name = "XXX";
        interface = "internal";
      };
    };
    cloudsPublicSettings = lib.mkDefault {
      public-clouds = {
        example-cloud = {
          auth = {
            auth_url = "https://identity.cloud.example.com/v2.0";
          };
        };
      };
    };

  };

  nmt.script = ''
    assertFileExists home-files/.config/openstack/clouds.yaml
    assertFileContent home-files/.config/openstack/clouds.yaml \
      ${./clouds.yaml}
    assertFileExists home-files/.config/openstack/clouds-public.yaml
    assertFileContent home-files/.config/openstack/clouds-public.yaml \
      ${./clouds-public.yaml}
  '';
}
