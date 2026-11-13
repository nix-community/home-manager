{ lib, options, ... }:

{
  programs.openstackclient = {
    enable = true;
    clouds = {
      legacy-cloud = {
        cloud = "legacy";
      };
      shared-cloud.interface = lib.mkForce "public";
      shared-cloud.region_name = lib.mkDefault "legacy";
    };
    cloudsSettings.clouds = {
      current-cloud = {
        cloud = "current";
      };
      shared-cloud.interface = "internal";
      shared-cloud.region_name = "current";
    };
    publicClouds = {
      legacy-cloud.auth.auth_url = "https://legacy.example.com";
    };
    cloudsPublicSettings.public-clouds = {
      current-cloud.auth.auth_url = "https://current.example.com";
    };
  };

  test.asserts.warnings.expected = [
    "The option `programs.openstackclient.publicClouds' defined in ${lib.showFiles options.programs.openstackclient.publicClouds.files} has been renamed to `programs.openstackclient.cloudsPublicSettings.public-clouds'."
    "The option `programs.openstackclient.clouds' defined in ${lib.showFiles options.programs.openstackclient.clouds.files} has been renamed to `programs.openstackclient.cloudsSettings.clouds'."
  ];

  nmt.script = ''
    assertFileContent home-files/.config/openstack/clouds.yaml ${./clouds-mixed.yaml}
    assertFileContent home-files/.config/openstack/clouds-public.yaml ${./clouds-public-mixed.yaml}
  '';
}
