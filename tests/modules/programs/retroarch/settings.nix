{ pkgs, ... }:
{
  imports = [ ./stubs.nix ];

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
    assertFileExists home-path/bin/retroarch
    assertFileRegex home-path/bin/retroarch 'appendconfig.*declarative-retroarch\.cfg'

    configFile=$(grep -aoP '/nix/store/[a-z0-9]+-declarative-retroarch\.cfg' $TESTED/home-path/bin/retroarch | head -1)
    assertFileExists "$configFile"
    assertFileContains "$configFile" 'input_max_users = "4"'
    assertFileContains "$configFile" 'menu_scale_factor = "0.950000"'
    assertFileContains "$configFile" 'netplay_nickname = "username"'
    assertFileContains "$configFile" 'video_driver = "vulkan"'
    assertFileContains "$configFile" 'video_fullscreen = "true"'
  '';
}
