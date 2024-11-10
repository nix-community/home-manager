{ ... }: {
  wayland.windowManager.wayfire = {
    enable = true;
    package = null;
    settings = {
      core.plugins = "command expo cube";
      command = {
        binding_terminal = "alacritty";
        command_terminal = "alacritty";
      };
    };
  };

  nmt.script = ''
    wayfireConfig=home-files/.config/wayfire.ini

    assertFileExists "$wayfireConfig"

    normalizedConfig=$(normalizeStorePaths "$wayfireConfig")
    assertFileContent "$normalizedConfig" "${./configuration.ini}"
  '';
}
