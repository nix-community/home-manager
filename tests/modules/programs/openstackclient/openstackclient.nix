{ ... }:

{
  programs.openstackclient = {
    enable = true;
    clouds = {
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
    publicClouds = {
      example-cloud = {
        auth = { auth_url = "https://identity.cloud.example.com/v2.0"; };
      };
    };

  };

  test.stubs.openstackclient = { };

  nmt.script = ''
    assertFileExists home-files/.config/openstack/clouds.yaml
    assertFileContent home-files/.config/openstack/clouds.yaml \
      ${./clouds.yaml}
    assertFileExists home-files/.config/openstack/clouds-public.yaml
    assertFileContent home-files/.config/openstack/clouds-public.yaml \
      ${./clouds-public.yaml}
  '';
}
