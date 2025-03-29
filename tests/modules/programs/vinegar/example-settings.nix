{ config, ... }: {
  programs.vinegar = {
    enable = true;
    package = config.lib.test.mkStubPackage { };

    settings = {
      env.WINEFSYNC = "1";

      studio = {
        dxvk = false;
        renderer = "Vulkan";

        fflags.DFIntTaskSchedulerTargetFps = 144;

        env = {
          DXVK_HUD = "0";
          MANGOHUD = "1";
        };
      };
    };
  };

  nmt.script = ''
    assertFileContent \
      home-files/.config/vinegar/config.toml \
      ${./example-config-expected.toml}
  '';
}
