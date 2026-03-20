{ config, ... }:
{
  programs.kraftkit = {
    enable = true;
    package = config.lib.test.mkStubPackage { };

    settings = {
      no_check_updates = true;
      collect_anonymous_telemetry = false;
      log = {
        level = "info";
        timestamps = false;
        type = "fancy";
      };
    };
  };

  nmt.script = ''
    assertFileExists "home-files/.config/kraftkit/config.yaml"
    assertFileContent \
      "home-files/.config/kraftkit/config.yaml" \
      ${./example-config-expected.yaml}
  '';
}
