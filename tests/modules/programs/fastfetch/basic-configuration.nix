{
  programs.fastfetch = {
    enable = true;
    settings = {
      logo = {
        source = "nixos_small";
        padding = { right = 1; };
      };
      display = {
        binaryPrefix = "si";
        color = "blue";
        separator = "  ";
      };
      modules = [
        {
          type = "datetime";
          key = "Date";
          format = "{1}-{3}-{11}";
        }
        {
          type = "datetime";
          key = "Time";
          format = "{14}:{17}:{20}";
        }
        "break"
        "player"
        "media"
      ];
    };
  };

  test.stubs.fastfetch = { };

  nmt.script = let configFile = "home-files/.config/fastfetch/config.jsonc";
  in ''
    assertFileExists "${configFile}"
    assertFileContent "${configFile}" ${./basic-configuration.jsonc}
  '';
}
