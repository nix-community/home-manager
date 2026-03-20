{
  services.redshift = {
    enable = true;
    provider = "manual";
    latitude = 0.0;
    longitude = "0.0";
    settings = {
      redshift = {
        adjustment-method = "randr";
        gamma = 0.8;
      };
      randr = {
        screen = 0;
      };
    };
    tray = true;
  };

  nmt.script = ''
    assertFileExists home-files/.config/redshift/redshift.conf
    assertFileContent \
        home-files/.config/redshift/redshift.conf \
        ${./redshift-basic-configuration-file-expected.conf}
    assertFileExists home-files/.config/systemd/user/redshift.service
    assertFileContent \
        home-files/.config/systemd/user/redshift.service \
        ${./redshift-tray-configuration-expected.service}
  '';
}
