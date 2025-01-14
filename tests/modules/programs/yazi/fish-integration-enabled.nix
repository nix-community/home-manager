{ config, ... }:

{
  programs.fish.enable = true;

  programs.yazi = {
    enable = true;
    shellWrapperName = "yy";
    enableFishIntegration = true;
  };

  test.stubs.yazi = { };

  nmt.script = ''
    assertFileContent home-files/.config/fish/functions/${config.programs.yazi.shellWrapperName}.fish \
      ${./fish-integration-expected.fish}
  '';
}
