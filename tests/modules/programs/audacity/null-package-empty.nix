{ config, lib, ... }:

{
  programs.audacity = {
    enable = true;
    package = null;
  };

  assertions = [
    {
      assertion = !(lib.any (package: lib.getName package == "audacity") config.home.packages);
      message = "A null Audacity package should not install Audacity.";
    }
    {
      assertion = !(config.home.activation ? audacitySettings);
      message = "Empty Audacity settings should not create an activation action.";
    }
  ];

  nmt.script = ''
    [[ ! -e home-files/.config/audacity/audacity.cfg ]]
    [[ ! -e home-files/.config/Audacity/Audacity4.ini ]]
  '';
}
