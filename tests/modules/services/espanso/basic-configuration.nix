{ ... }:

{
  services.espanso = {
    enable = true;
    configs = { default = { show_notifications = false; }; };
    matches = {
      base = {
        matches = [
          {
            trigger = ":now";
            replace = "It's {{currentdate}} {{currenttime}}";
          }
          {
            trigger = ":hello";
            replace = ''
              line1
              line2'';
          }
          {
            regex = ":hi(?P<person>.*)\\.";
            replace = "Hi {{person}}!";
          }
        ];
        global_vars = [
          {
            name = "currentdate";
            type = "date";
            params = { format = "%d/%m/%Y"; };
          }
          {
            name = "currenttime";
            type = "date";
            params = { format = "%R"; };
          }
        ];
      };
    };
  };

  test.stubs.espanso = { };

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/espanso.service
    assertFileExists "$serviceFile"
    assertFileContent "$serviceFile" ${./basic-configuration.service}

    configFile=home-files/.config/espanso/config/default.yml
    assertFileExists "$configFile"
    assertFileContent "$configFile" ${./basic-configuration.yaml}

    matchFile=home-files/.config/espanso/match/base.yml
    assertFileExists "$matchFile"
    assertFileContent "$matchFile" ${./basic-matches.yaml}
  '';
}
