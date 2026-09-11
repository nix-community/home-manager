{ lib, options, ... }:
{
  programs.openstackclient = {
    enable = true;
    package = null;
    clouds = { };
    publicClouds = { };
  };

  test.asserts.warnings.expected = [
    "The option `programs.openstackclient.publicClouds' defined in ${lib.showFiles options.programs.openstackclient.publicClouds.files} has been renamed to `programs.openstackclient.cloudsPublicSettings.public-clouds'."
    "The option `programs.openstackclient.clouds' defined in ${lib.showFiles options.programs.openstackclient.clouds.files} has been renamed to `programs.openstackclient.cloudsSettings.clouds'."
  ];

  nmt.script = ''
    assertFileContent home-files/.config/openstack/clouds.yaml ${./clouds-empty.yaml}
    assertFileContent home-files/.config/openstack/clouds-public.yaml ${./clouds-public-empty.yaml}
  '';
}
