{ config, ... }:
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
}
