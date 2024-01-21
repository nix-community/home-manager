{ config, pkgs, ... }: {
  programs = {
    mise = {
      package = config.lib.test.mkStubPackage { name = "mise"; };
      enable = true;
      globalConfig = {
        tools = {
          node = "lts";
          python = [ "3.10" "3.11" ];
        };

        aliases = { my_custom_node = "20"; };
      };
      settings = {
        verbose = false;
        experimental = true;
        disable_tools = [ "node" ];
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/mise/config.toml
    assertFileExists home-files/.config/mise/settings.toml

    assertFileContent home-files/.config/mise/config.toml ${
      pkgs.writeText "mise.config.expected" ''
        [aliases]
        my_custom_node = "20"

        [tools]
        node = "lts"
        python = ["3.10", "3.11"]
      ''
    }

    assertFileContent home-files/.config/mise/settings.toml ${
      pkgs.writeText "mise.settings.expected" ''
        disable_tools = ["node"]
        experimental = true
        verbose = false
      ''
    }
  '';
}
