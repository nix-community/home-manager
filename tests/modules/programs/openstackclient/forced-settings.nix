{ lib, options, ... }:
{
  programs.openstackclient = {
    enable = true;
    package = null;
    clouds = _: { ignored.auth.username = "legacy"; };
    publicClouds = _: { ignored.auth.auth_url = "https://legacy.example.com"; };
    cloudsSettings = lib.mkForce { cache.auth = false; };
    cloudsPublicSettings = lib.mkForce { };
  };

  test.asserts.warnings.expected = [
    "The option `programs.openstackclient.publicClouds' defined in ${lib.showFiles options.programs.openstackclient.publicClouds.files} has been renamed to `programs.openstackclient.cloudsPublicSettings.public-clouds'."
    "The option `programs.openstackclient.clouds' defined in ${lib.showFiles options.programs.openstackclient.clouds.files} has been renamed to `programs.openstackclient.cloudsSettings.clouds'."
  ];

  nmt.script = ''
    assertFileContent home-files/.config/openstack/clouds.yaml ${./forced-settings.yaml}
    assertPathNotExists home-files/.config/openstack/clouds-public.yaml
  '';
}
