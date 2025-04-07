{ pkgs, ... }:
{
  services.jankyborders = {
    enable = true;
    settings = {
      active_color = "0xffe2e2e3";
      hidpi = "off";
      inactive_color = "0xff414550";
      style = "round";
      width = 6.0;
    };
  };

  nmt.script = ''
    configFile=home-files/.config/borders/bordersrc
    assertFileExists $configFile
    assertFileIsExecutable "$configFile"
    # assertFileContent $configFile ${./jankyborders-config-expected}
    assertFileContent "$configFile" ${pkgs.writeShellScript "bordersrc" (builtins.readFile ./jankyborders-config-expected)}

    serviceFile=LaunchAgents/org.nix-community.home.jankyborders.plist
    assertFileExists "$serviceFile"
  '';
}
