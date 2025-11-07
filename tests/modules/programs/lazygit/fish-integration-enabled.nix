{ config, ... }:

{
  programs.fish.enable = true;

  home.preferXdgDirectories = false;

  programs.lazygit = {
    enable = true;
    shellWrapperName = "lg";
    enableFishIntegration = true;
  };

  nmt.script = ''
    assertFileContent home-files/.config/fish/functions/${config.programs.lazygit.shellWrapperName}.fish \
      ${./fish-integration-expected.fish}
  '';
}
