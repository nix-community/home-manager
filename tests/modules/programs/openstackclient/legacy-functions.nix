{ lib, options, ... }:
{
  programs.openstackclient = {
    enable = true;
    package = null;
    clouds = { lib, ... }: {
      demo.auth.username = lib.mkDefault "legacy";
      demo.region_name = "RegionOne";
    };
    publicClouds = { lib, ... }: {
      demo.auth.auth_url = lib.mkDefault "https://legacy.example.com";
    };
    cloudsSettings.clouds.demo.auth.username = "canonical";
    cloudsPublicSettings.public-clouds.demo.auth.auth_url = "https://identity.example.com";
  };
  test.asserts.warnings.expected = [
    "The option `programs.openstackclient.publicClouds' defined in ${lib.showFiles options.programs.openstackclient.publicClouds.files} has been renamed to `programs.openstackclient.cloudsPublicSettings.public-clouds'."
    "The option `programs.openstackclient.clouds' defined in ${lib.showFiles options.programs.openstackclient.clouds.files} has been renamed to `programs.openstackclient.cloudsSettings.clouds'."
  ];
  nmt.script = ''
    assertFileContent home-files/.config/openstack/clouds.yaml ${./legacy-functions.yaml}
    assertFileContent home-files/.config/openstack/clouds-public.yaml ${./root-defaults-public.yaml}
  '';
}
