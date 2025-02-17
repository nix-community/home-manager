{ config, ... }: {
  programs.ghostty = {
    enable = true;
    package = config.lib.test.mkStubPackage { };

    settings = {
      theme = "catppuccin-mocha";
      font-size = 10;
    };
  };

  nmt.script = ''
    assertFileContent \
      home-files/.config/ghostty/config \
      ${./example-config-expected}
  '';
}
