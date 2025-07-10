{ config, ... }:
{
  wayland.windowManager.wayfire = {
    enable = true;
    package = null;
    settings = {
      core.plugins = "command expo cube";
      command = {
        binding_terminal = "alacritty";
        command_terminal = "alacritty";
      };
      cube.skydome_texture = config.lib.test.mkStubPackage { };
    };
  };

  nmt.script = ''
    wayfireConfig=home-files/.config/wayfire.ini

    assertFileExists "$wayfireConfig"
    assertFileContent "$wayfireConfig" "${./configuration.ini}"
  '';
}
