{ config, ... }:
{
  programs.cline = {
    enable = true;
    package = null;
    mutableSettings = true;
  };

  assertions = [
    {
      assertion = !(config.home.activation ? clineSettings);
      message = "Empty Cline settings must not register mutable settings activation.";
    }
  ];

  nmt.script = ''
    assertPathNotExists home-files/.cline
  '';
}
