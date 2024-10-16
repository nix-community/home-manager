espansoExtraArgs:
{ config, ... }:

{
  services.espanso = {
    enable = true;
    configs = {
      default = {
        show_notifications = false;
      };
    };
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
            params = {
              format = "%d/%m/%Y";
            };
          }
          {
            name = "currenttime";
            type = "date";
            params = {
              format = "%R";
            };
          }
        ];
      };
    };
  } // espansoExtraArgs;

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/espanso.service
    expectedServiceFile=${./basic-configuration.service}
    assertFileExists "$serviceFile"
    # ensure espanso is in ExecStart
    assertFileRegex "$serviceFile" 'ExecStart=.*/bin/espanso launcher'
    # rest of the file should be identical
    grep -v "/bin/espanso launcher" "$(_abs $serviceFile)" > espanso-service.actual
    grep -v "/bin/espanso launcher" "$expectedServiceFile" > espanso-service.expected
    assertFileContent "$(realpath espanso-service.actual)" espanso-service.expected

    configFile=home-files/.config/espanso/config/default.yml
    assertFileExists "$configFile"
    assertFileContent "$configFile" ${./basic-configuration.yaml}

    matchFile=home-files/.config/espanso/match/base.yml
    assertFileExists "$matchFile"
    assertFileContent "$matchFile" ${./basic-matches.yaml}
  '';
}
