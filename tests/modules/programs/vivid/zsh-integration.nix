{ config, ... }:
{
  programs.zsh.enable = true;

  programs.vivid = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "vivid";
      outPath = "@vivid@";
    };
    enableZshIntegration = true;
  };

  nmt.script = ''
    assertFileContains home-files/.zshrc 'export LS_COLORS="$(@vivid@/bin/vivid generate)"'
  '';
}
