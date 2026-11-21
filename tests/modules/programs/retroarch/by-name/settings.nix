_: {
  programs.retroarch = {
    enable = true;
    settings = {
      input_max_users = "4";
      menu_scale_factor = "0.950000";
      netplay_nickname = "username";
      video_driver = "vulkan";
      video_fullscreen = "true";
    };
  };

  nmt.script = ''
    configFile="home-files/.config/retroarch/retroarch.cfg"
    assertFileExists "$configFile"
    assertFileContains "$configFile" 'config_save_on_exit = "false"'
    assertFileContains "$configFile" 'input_max_users = "4"'
    assertFileContains "$configFile" 'menu_scale_factor = "0.950000"'
    assertFileContains "$configFile" 'netplay_nickname = "username"'
    assertFileContains "$configFile" 'video_driver = "vulkan"'
    assertFileContains "$configFile" 'video_fullscreen = "true"'
  '';
}
