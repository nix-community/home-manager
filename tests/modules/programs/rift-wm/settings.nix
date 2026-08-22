{ config, ... }:
{
  programs.rift-wm = {
    enable = true;
    package = config.lib.test.mkStubPackage { name = "rift-wm"; };
    launchd.enable = true;
    settings = {
      animate = true;
      hot_reload = true;
      layout = {
        mode = "bsp";
        gaps.outer = {
          top = 0.5;
          left = 0.5;
          right = 0.5;
          bottom = 0.5;
        };
      };

      keys = {
        "Alt + H".move_focus = "left";
        "Alt + Shift + Left".join_window = "left";
        "Alt + 1".switch_to_workspace = 1;
        "comb1 + S".switch_to_workspace = 2;
      };
    };
  };

  nmt.script = ''
    assertFileContent "home-files/.config/rift/config.toml" ${./settings-expected.toml}

    serviceFile=$(normalizeStorePaths LaunchAgents/org.nix-community.home.rift-wm.plist)
    assertFileExists $serviceFile
    assertFileContent "$serviceFile" ${./service-expected.plist}
  '';
}
