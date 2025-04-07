{
  services.macos-remap-keys = {
    enable = true;
    keyboard = {
      Capslock = "Backspace";
    };
  };

  nmt.script = ''
    launchAgent=LaunchAgents/org.nix-community.home.remap-keys.plist
    assertFileExists "$launchAgent"
    assertFileContent "$launchAgent" ${./basic-agent.plist}
  '';
}
