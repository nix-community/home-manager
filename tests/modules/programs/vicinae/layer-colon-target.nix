{ config, lib, ... }:
{
  home.file."${config.xdg.configHome}/vicinae/home-manager.json".target =
    lib.mkForce "layers/vicinae:personal.json";
  programs.vicinae = {
    enable = true;
    mutableSettings = true;
    package = null;
    settings.font.normal.size = 12;
  };
  test.asserts.assertions.expected = [
    "programs.vicinae.mutableSettings cannot use a configuration path containing ':' because VICINAE_OVERRIDES is a colon-separated list."
  ];
  nmt.script = ''
    assertFileContent "home-files/layers/vicinae:personal.json" ${./read-only-layer.json}
  '';
}
