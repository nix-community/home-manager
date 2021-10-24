{ ... }:

{
  services.espanso = {
    enable = true;
    settings = {
      matches = [
        { # Simple text replacement
          trigger = ":espanso";
          replace = "Hi there!";
        }
        { # Dates
          trigger = ":date";
          replace = "{{mydate}}";
          vars = [{
            name = "mydate";
            type = "date";
            params = { format = "%m/%d/%Y"; };
          }];
        }
        { # Shell commands
          trigger = ":shell";
          replace = "{{output}}";
          vars = [{
            name = "output";
            type = "shell";
            params = { cmd = "echo Hello from your shell"; };
          }];
        }
      ];
    };
  };

  test.stubs.espanso = { };

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/espanso.service
    assertFileExists "$serviceFile"
    assertFileContent "$serviceFile" ${./basic-configuration.service}

    configFile=home-files/.config/espanso/default.yml
    assertFileExists "$configFile"
    assertFileContent "$configFile" ${./basic-configuration.yaml}
  '';
}
