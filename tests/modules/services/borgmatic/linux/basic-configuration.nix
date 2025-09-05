{
  services.borgmatic = {
    enable = true;
    frequency = "weekly";
  };

  nmt.script = ''
    assertFileContent \
      $(normalizeStorePaths home-files/.config/systemd/user/borgmatic.service) \
      ${./basic-configuration.service}

    assertFileContent \
      home-files/.config/systemd/user/borgmatic.timer \
      ${./basic-configuration.timer}
  '';
}
