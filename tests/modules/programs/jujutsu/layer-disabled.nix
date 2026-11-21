{ config, ... }:
{
  programs.jujutsu = {
    enable = false;
    mutableSettings = true;
    package = null;
    settings.user.name = "Declarative";
  };
  assertions = [
    {
      assertion = !(config.home.activation ? jujutsu-user-config);
      message = "Empty or disabled Jujutsu settings must not seed user configuration.";
    }
  ];
  nmt.script = ''
    assertPathNotExists "home-files/.config/jj/conf.d/home-manager.toml"
    assertPathNotExists "home-files/.config/jj/config.toml"
  '';
}
