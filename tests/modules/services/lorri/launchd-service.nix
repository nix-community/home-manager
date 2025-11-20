{
  services.lorri.enable = true;

  nmt.script = ''
    serviceFile="LaunchAgents/org.nix-community.home.lorri.plist"
    assertFileExists "$serviceFile"
    assertFileContains "$serviceFile" "/bin/lorri daemon"
    assertFileContains "$serviceFile" "<key>RunAtLoad</key>"
    assertFileContains "$serviceFile" "<key>KeepAlive</key>"
  '';
}
