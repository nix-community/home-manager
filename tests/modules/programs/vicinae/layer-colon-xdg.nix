{ config, ... }:
{
  xdg.configHome = "${config.home.homeDirectory}/config:personal";
  programs.vicinae = {
    enable = true;
    enableMutableConfig = true;
    package = null;
    settings.font.normal.size = 12;
  };
  test.asserts.assertions.expected = [
    "programs.vicinae.enableMutableConfig cannot use a configuration path containing ':' because VICINAE_OVERRIDES is a colon-separated list."
  ];
  nmt.script = ''
    assertFileContent "home-files/config:personal/vicinae/home-manager.json" ${./read-only-layer.json}
  '';
}
