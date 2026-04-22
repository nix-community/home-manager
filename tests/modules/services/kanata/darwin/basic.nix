_: {
  test.stubs.kanata = { };

  services.kanata = {
    enable = true;
    keyboards.main = {
      devices = [ "Example Keyboard" ];
      defsrc = [
        "caps"
        "a"
      ];
      layers.base = [
        "esc"
        "a"
      ];
    };
  };

  nmt.script = ''
    plistFile="LaunchAgents/org.nix-community.home.kanata-main.plist"
    assertFileExists "$plistFile"

    plistFile="$(normalizeStorePaths "$plistFile")"
    assertFileContent "$plistFile" ${./basic-expected.plist}

    assertFileContent \
      home-files/.config/kanata/main.kbd \
      ${./basic-expected.kbd}
  '';
}
