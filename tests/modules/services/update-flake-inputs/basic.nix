{
  services.update-flake-inputs = {
    enable = true;
    directories = [ "/some/path" ];
  };

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/update-flake-inputs.service
    normalizedServiceFile=$(normalizeStorePaths "$serviceFile")
    assertFileContent $normalizedServiceFile ${./expected-basic.service}

    assertFileContent home-files/.config/systemd/user/update-flake-inputs.timer ${./expected-basic.timer}
  '';
}
