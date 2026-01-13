{
  config,
  pkgs,
  ...
}:
{
  programs = {
    mise = {
      package = config.lib.test.mkStubPackage { name = "mise"; };
      enable = true;
      globalConfig = {
        settings = {
          disable_tools = [ "node" ];
          experimental = true;
          verbose = false;
        };

        tool_alias = {
          node.versions = {
            my_custom_node = "20";
          };
        };

        tools = {
          node = "lts";
          python = [
            "3.10"
            "3.11"
          ];
        };
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/mise/config.toml

    assertFileContent home-files/.config/mise/config.toml ${pkgs.writeText "mise.config.expected" ''
      [settings]
      disable_tools = ["node"]
      experimental = true
      verbose = false

      [tool_alias.node.versions]
      my_custom_node = "20"

      [tools]
      node = "lts"
      python = ["3.10", "3.11"]
    ''}
  '';
}
