{
  services.lorri = {
    enable = true;
    extraEnvVariables = {
      TEST_ENV_VAR = "test-value";
      ANOTHER_ENV_VAR = "another-value";
    };
  };

  nmt.script = ''
    serviceFile="home-files/.config/systemd/user/lorri.service"
    assertFileExists "$serviceFile"
    assertFileContains "$serviceFile" "Environment=TEST_ENV_VAR=test-value"
    assertFileContains "$serviceFile" "Environment=ANOTHER_ENV_VAR=another-value"
  '';
}
