{
  config,
  lib,
  ...
}:
{
  programs.andcli = {
    enable = lib.mkDefault true;
    mutableSettings = lib.mkDefault true;
    package = null;
  };
  xdg.configHome = "${config.home.homeDirectory}/custom-config";

  assertions = [
    {
      assertion = !(config.home.activation ? andcliMutableSettings);
      message = "andcli empty-settings must not create mutable activation.";
    }
  ];

  nmt.script = ''
    assertPathNotExists "home-files/custom-config/andcli/config.yaml"
    assertPathNotExists "home-files/Library/Application Support/andcli/config.yaml"
  '';
}
