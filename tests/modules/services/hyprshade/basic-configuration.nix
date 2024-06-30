{ pkgs, ... }: {
  services.hyprshade = {
    enable = true;
    package = pkgs.hyprshade;

    schedule = [
      {
        name = "vibrance";
        default = true;
      }
      {
        name = "blue-light-filter";
        startTime = "06:00:00";
        endTime = "19:00:00";
      }
      {
        name = "color-filter";
        config = {
          type = "red-green";
          strength = 0.5;
        };
      }
    ];
    systemd.enable = true;
  };

  test.stubs.hyprshade = { };

  nmt.script = ''
    config=home-files/.config/hypr/hyprshade.toml
    clientServiceFile=home-files/.config/systemd/user/hyprshade.service
    assertFileExists $config
    assertFileExists $clientServiceFile
    assertFileContent $config ${./hyprshade.toml}
  '';
}
