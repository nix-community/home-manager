{
  programs.comodoro = {
    enable = true;
    settings = {
      accounts.example = {
        default = true;

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

        precision = "minute";

        socket.default = true;
        tcp.host = "localhost";
        tcp.port = 8080;

        hooks.on-timer-stop.command = "echo timer stopped";
        hooks.on-work-begin.notify = {
          summary = "Comodoro";
          body = "Work started!";
        };
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/comodoro/config.toml
    assertFileContent home-files/.config/comodoro/config.toml ${./expected.toml}
  '';
}
