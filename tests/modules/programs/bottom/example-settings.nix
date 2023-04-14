{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.bottom = {
      enable = true;
      package = config.lib.test.mkStubPackage { };

      settings = {
        flags = {
          avg_cpu = true;
          temperature_type = "c";
        };

        colors = { low_battery_color = "red"; };
      };
    };

    nmt.script = ''
      assertFileContent \
        "home-files/.config/bottom/bottom.toml" \
        ${./example-settings-expected.toml}
    '';
  };
}
