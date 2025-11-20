{
  services.lorri = {
    enable = true;
    extraEnvVariables.TEST_ENV_VAR = "test-value";
  };

  nmt.script = ''
    serviceFile="LaunchAgents/org.nix-community.home.lorri.plist"
    assertFileExists "$serviceFile"
    assertFileContains "$serviceFile" "<key>TEST_ENV_VAR</key>"
    assertFileContains "$serviceFile" "<string>test-value</string>"
  '';
}
