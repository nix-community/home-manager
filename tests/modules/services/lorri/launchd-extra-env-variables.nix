{
  services.lorri = {
    enable = true;
    extraEnvVariables = {
      TEST_ENV_VAR = "test-value";
      ANOTHER_ENV_VAR = "another-value";
    };
  };

  nmt.script = ''
    serviceFile="LaunchAgents/org.nix-community.home.lorri.plist"
    assertFileExists "$serviceFile"
    assertFileContains "$serviceFile" "<key>TEST_ENV_VAR</key>"
    assertFileContains "$serviceFile" "<string>test-value</string>"
    assertFileContains "$serviceFile" "<key>ANOTHER_ENV_VAR</key>"
    assertFileContains "$serviceFile" "<string>another-value</string>"
  '';
}
