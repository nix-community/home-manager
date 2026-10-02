{ config, ... }:
{
  xdg.configHome = "${config.home.homeDirectory}/.custom";
  programs.jujutsu = {
    enable = true;
    mutableSettings = true;
    package = null;
    settings.user.name = "Declarative";
  };
  nmt.script = ''
    assertFileContent "home-files/.custom/jj/conf.d/home-manager.toml" ${./read-only-layer.toml}
    assertPathNotExists "home-files/.custom/jj/config.toml"
    assertFileContains activate '${config.xdg.configHome}/jj/config.toml'
  '';
}
