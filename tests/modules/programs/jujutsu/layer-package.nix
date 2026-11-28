{ config, ... }:
{
  programs.jujutsu = {
    enable = true;
    mutableSettings = true;
    settings.user.name = "Declarative";
  };
  assertions = [
    {
      assertion = builtins.elem config.programs.jujutsu.package config.home.packages;
      message = "Mutable Jujutsu must still install its configured package.";
    }
    {
      assertion = config.home.activation.jujutsu-user-config.after == [ "linkGeneration" ];
      message = "Jujutsu must initialize the writable config after linking its declared fragment.";
    }
  ];
  nmt.script = ''
    assertFileContent home-files/.config/jj/conf.d/home-manager.toml ${./read-only-layer.toml}
    assertPathNotExists home-files/.config/jj/config.toml
    assertFileContains activate '${config.xdg.configHome}/jj/config.toml'
  '';
}
