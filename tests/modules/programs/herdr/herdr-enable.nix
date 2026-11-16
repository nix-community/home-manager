{ config, ... }:
{
  xdg.enable = true;

  programs.herdr.enable = true;

  assertions = [
    {
      assertion = !(config.home.activation ? herdrMutableSettings);
      message = "Empty Herdr settings must not register mutable activation.";
    }
    {
      assertion = !(config.home.activation ? herdrImmutableSettings);
      message = "Empty Herdr settings must not register immutable cleanup.";
    }
  ];

  test.asserts.warnings.expected = [ ];

  nmt.script = ''
    assertPathNotExists "home-files/.config/herdr/config.toml"
  '';
}
