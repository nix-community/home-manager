{ config, ... }:
{
  xdg.configHome = "${config.home.homeDirectory}/custom-config";
  programs.alistral = {
    enable = true;
    mutableSettings = true;
  };
  assertions = [
    {
      assertion = !(config.home.activation ? alistralMutableSettings);
      message = "Inactive alistral settings must not create mutable activation.";
    }
    {
      assertion = !(config.home.activation ? alistralImmutableSettings);
      message = "Inactive alistral settings must not create immutable cleanup.";
    }
  ];
  nmt.script = ''
    assertPathNotExists "home-files/custom-config/alistral/config.json"
    assertPathNotExists "home-files/Library/Application Support/alistral/config.json"
  '';
}
