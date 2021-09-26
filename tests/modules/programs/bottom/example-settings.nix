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

    nmt.script = let
      configDir = if pkgs.stdenv.isDarwin then
        "home-files/Library/Application Support"
      else
        "home-files/.config";
    in ''
      assertFileContent \
        "${configDir}/bottom/bottom.toml" \
        ${
          builtins.toFile "example-settings-expected.toml" ''
            [colors]
            low_battery_color = "red"

            [flags]
            avg_cpu = true
            temperature_type = "c"
          ''
        }
    '';
  };
}
