{ config, ... }:
{
  programs.herdr = {
    mutableSettings = true;
    settings.onboarding = false;
  };
  assertions = [
    {
      assertion = !(config.home.activation ? herdrMutableSettings);
      message = "Disabled Herdr must not register mutable activation.";
    }
    {
      assertion = !(config.home.activation ? herdrImmutableSettings);
      message = "Disabled Herdr must not register immutable cleanup.";
    }
  ];
  nmt.script = ''
    assertPathNotExists home-files/.config/herdr/config.toml
  '';
}
