{ pkgs, ... }:

let
  configFile =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "home-files/Library/Application Support/KeePassXC/keepassxc.ini"
    else
      "home-files/.config/keepassxc/keepassxc.ini";
in
{
  programs.keepassxc = {
    enable = true;
    settings = {
      Browser.Enabled = true;
      GUI = {
        AdvancedSettings = true;
        ApplicationTheme = "dark";
        CompactMode = true;
        HidePasswords = true;
      };
      SSHAgent.Enabled = true;
    };
  };

  test.stubs.keepassxc = { };

  nmt.script = ''
    assertFileContent "${configFile}" ${./keepassxc-example-config.ini}
  '';
}
