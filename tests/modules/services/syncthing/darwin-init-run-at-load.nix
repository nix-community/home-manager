{
  services.syncthing = {
    enable = true;
    settings.options.relaysEnabled = false;
  };

  nmt.script = ''
    serviceFile=LaunchAgents/org.nix-community.home.syncthing-init.plist
    assertFileExists "$serviceFile"
    assertFileContains "$serviceFile" "<key>RunAtLoad</key>"
    assertFileContains "$serviceFile" "<true/>"
  '';
}
