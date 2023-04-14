{ ... }:

{
  programs.comodoro = {
    enable = true;
    settings = {
      test-preset = {
        cycles = [
          {
            name = "Work";
            duration = 1500;
          }
          {
            name = "Rest";
            duration = 500;
          }
        ];

        tcp-host = "localhost";
        tcp-port = 8080;

        on-server-start = "echo server started";
        on-timer-stop = "echo timer stopped";
        on-work-begin = "echo work cycle began";
      };
    };
  };

  test.stubs.comodoro = { };

  nmt.script = ''
    assertFileExists home-files/.config/comodoro/config.toml
    assertFileContent home-files/.config/comodoro/config.toml ${./expected.toml}
  '';
}
