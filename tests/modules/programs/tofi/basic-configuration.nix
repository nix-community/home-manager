{ config, pkgs, ... }: {
  config = {
    programs.tofi = {
      enable = true;
      package = pkgs.tofi;
      settings = {
        background-color = "#000000";
        border-width = 0;
        font = "monospace";
        height = "100%";
        num-results = 5;
        outline-width = 0;
        padding-left = "35%";
        padding-top = "35%";
        result-spacing = 25;
        width = "100%";
      };
    };

    test.stubs.tofi = { };

    nmt.script = ''
      assertFileExists home-files/.config/tofi/config
      assertFileContent home-files/.config/tofi/config \
        ${./basic-configuration.conf}
    '';
  };
}
