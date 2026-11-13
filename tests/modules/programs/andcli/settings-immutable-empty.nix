{
  config,
  ...
}:
{
  programs.andcli = {
    enable = true;
    mutableSettings = false;
    package = null;
  };
  xdg.configHome = "${config.home.homeDirectory}/custom-config";

  assertions = [
    {
      assertion = !(config.home.activation ? andcliMutableSettings);
      message = "andcli settings-immutable-empty must not create mutable activation.";
    }
  ];

  nmt.script = ''
    assertPathNotExists "home-files/custom-config/andcli/config.yaml"
    assertPathNotExists "home-files/Library/Application Support/andcli/config.yaml"
  '';
}
