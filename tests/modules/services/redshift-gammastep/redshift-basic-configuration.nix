{ config, pkgs, ... }:

{
  config = {
    services.redshift = {
      enable = true;
      provider = "manual";
      latitude = 0.0;
      longitude = "$XDG_RUNTIME_DIR/longitude";
      settings = {
        redshift = {
          adjustment-method = "randr";
          gamma = 0.8;
        };
        randr = { screen = 0; };
      };
    };

    test.stubs.redshift = { };

    nmt.script = ''
      export XDG_RUNTIME_DIR="$(mktemp --directory)"
      echo 0.0 > "$XDG_RUNTIME_DIR/longitude"

      assertFileContent \
          home-files/.config/redshift/redshift.conf \
          ${./redshift-basic-configuration-file-expected.conf}
      assertFileContent \
          home-files/.config/systemd/user/redshift.service \
          ${./redshift-basic-configuration-expected.service}
    '';
  };
}
