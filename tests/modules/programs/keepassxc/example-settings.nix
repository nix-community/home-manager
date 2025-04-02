{ ... }:

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
    configFile=home-files/.config/keepassxc/keepassxc.ini
    assertFileContent $configFile ${./keepassxc-example-config.ini}
  '';
}
