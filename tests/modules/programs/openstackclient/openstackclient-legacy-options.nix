{
  lib,
  options,
  ...
}:
{
  programs.openstackclient = {
    enable = true;
    clouds = {
      my-infra = {
        cloud = "example-cloud";
        auth.username = "openstack";
      };
    };
    publicClouds = {
      example-cloud.auth.auth_url = "https://identity.cloud.example.com/v2.0";
    };
  };

  test.asserts.warnings.expected = [
    "The option `programs.openstackclient.publicClouds' defined in ${lib.showFiles options.programs.openstackclient.publicClouds.files} has been renamed to `programs.openstackclient.cloudsPublicSettings.public-clouds'."
    "The option `programs.openstackclient.clouds' defined in ${lib.showFiles options.programs.openstackclient.clouds.files} has been renamed to `programs.openstackclient.cloudsSettings.clouds'."
  ];

  nmt.script = ''
    assertFileExists home-files/.config/openstack/clouds.yaml
    assertFileContent home-files/.config/openstack/clouds.yaml ${./clouds-legacy.yaml}
    assertFileExists home-files/.config/openstack/clouds-public.yaml
    assertFileContent home-files/.config/openstack/clouds-public.yaml ${./clouds-public.yaml}
  '';
}
