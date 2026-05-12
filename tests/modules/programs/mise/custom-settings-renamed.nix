{
  config,
  lib,
  options,
  pkgs,
  ...
}:
{
  programs = {
    mise = {
      package = config.lib.test.mkStubPackage { name = "mise"; };
      enable = true;
      settings = {
        disable_tools = [ "node" ];
        experimental = true;
        verbose = false;
      };
    };
  };

  test.asserts.warnings.expected = [
    "The option `programs.mise.settings' defined in ${lib.showFiles options.programs.mise.settings.files} has been renamed to `programs.mise.globalConfig.settings'."
  ];

  nmt.script = ''
    assertFileExists home-files/.config/mise/config.toml

    assertFileContent home-files/.config/mise/config.toml ${pkgs.writeText "mise.config.expected" ''
      [settings]
      disable_tools = ["node"]
      experimental = true
      verbose = false
    ''}
  '';
}
