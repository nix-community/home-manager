{ config, pkgs, ... }: {
  programs = {
    rtx = {
      package = config.lib.test.mkStubPackage { name = "rtx"; };
      enable = true;
      settings = {
        tools = {
          node = "lts";
          python = [ "3.10" "3.11" ];
        };

        settings = {
          verbose = false;
          experimental = false;
        };
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/rtx/config.toml

    assertFileContent home-files/.config/rtx/config.toml ${
      pkgs.writeText "rtx.expected" ''
        [settings]
        experimental = false
        verbose = false

        [tools]
        node = "lts"
        python = ["3.10", "3.11"]
      ''
    }
  '';
}
