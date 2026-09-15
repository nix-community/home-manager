{ config, pkgs, ... }:
let
  wayleTestLib = import ./lib.nix { inherit config pkgs; };
  inherit (wayleTestLib.asserts) awwwInstalled packageInstalled;
in
{
  services.wayle = {
    enable = true;
    package = config.lib.test.mkStubPackage { name = "wayle"; };

    settings = {
      styling = {
        theme-provider = "wayle";

        palette = {
          bg = "#16161e";
          fg = "#c0caf5";
          primary = "#7aa2f7";
        };
      };

      bar = {
        scale = 1;
        location = "top";
        rounding = "sm";

        layout = [
          {
            monitor = "*";
            left = [ "clock" ];
            center = [ "media" ];
            right = [ "battery" ];
          }
        ];
      };

      modules.clock = {
        format = "%H:%M";
        icon-show = true;
        label-show = true;
      };
    };
  };

  nmt.script = ''
    assertFileContent \
      "home-files/.config/wayle/config.toml" \
      ${./basic-config.toml}
  '';

  assertions = [
    (awwwInstalled false)
    (packageInstalled "matugen" false)
    (packageInstalled "wallust" false)
    (packageInstalled "pywal" false)
  ];
}
