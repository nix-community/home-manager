{
  config,
  lib,
  options,
  ...
}:
{
  programs.mise = {
    enable = true;
    package = config.lib.test.mkStubPackage { name = "mise"; };
    enableMutableConfig = true;
    globalConfig.env.HM_TEST = "home-manager";
  };

  test.asserts.warnings.expected = [
    "The option `programs.mise.enableMutableConfig' defined in ${lib.showFiles options.programs.mise.enableMutableConfig.files} has been renamed to `programs.mise.mutableSettings'."
  ];

  assertions = [
    {
      assertion = lib.hasInfix "run touch" config.home.activation.miseMutableConfig.data;
      message = "The renamed option must still create the writable Mise configuration file.";
    }
  ];

  nmt.script = ''
    assertPathNotExists home-files/.config/mise/config.toml
    assertFileContent home-files/.config/mise/conf.d/50-home-manager.toml ${./mutable-config.toml}
  '';
}
