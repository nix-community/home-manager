{
  services.glance = {
    enable = true;
    settings = {
      server.port = 5678;
      pages = [{
        name = "Home";
        columns = [{
          size = "full";
          widgets = [
            { type = "calendar"; }
            {
              type = "weather";
              location = "London, United Kingdom";
            }
          ];
        }];
      }];
    };
  };

  nmt.script = ''
    configFile=home-files/.config/glance/glance.yml
    serviceFile=home-files/.config/systemd/user/glance.service

    assertFileContent $configFile ${./glance-example-config.yml}
    assertFileContent $serviceFile ${./glance.service}
  '';
}
