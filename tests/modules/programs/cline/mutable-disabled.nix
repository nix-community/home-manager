{ config, ... }:
{
  programs.cline = {
    enable = false;
    package = null;
    mutableSettings = true;
    providers.version = 1;
  };

  assertions = [
    {
      assertion = !(config.home.activation ? clineSettings);
      message = "Disabled Cline must not register mutable settings activation.";
    }
  ];

  nmt.script = ''
    assertPathNotExists home-files/.cline
  '';
}
