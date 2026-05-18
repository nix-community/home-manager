{
  services.elephant = {
    enable = true;
    settings = {
      providers = {
        default = [
          "desktopapplications"
          "runner"
        ];
        max_results = 50;
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/elephant/config.toml
    assertFileExists home-files/.config/systemd/user/elephant.service

    assertFileContent home-files/.config/elephant/config.toml \
    ${./config.toml}

    assertFileContent home-files/.config/systemd/user/elephant.service \
    ${./elephant.service}
  '';
}
