{ config, ... }: {
  programs.swayimg = {
    enable = true;
    package = config.lib.test.mkStubPackage { };
    settings = {
      general = {
        scale = "optimal";
        fullscreen = "no";
        antialiasing = "no";
        fixed = "yes";
        transparency = "grid";
        position = "parent";
        size = "parent";
      };
      font = {
        name = "monospace";
        size = 14;
      };
    };
  };

  nmt.script = let homeConfig = "home-files/.config/swayimg/config";
  in ''
    assertFileExists ${homeConfig}
    assertFileContents ${homeConfig} ${./config}
  '';
}
