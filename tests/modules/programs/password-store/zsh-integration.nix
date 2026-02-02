{ config, ... }:
{
  programs = {
    zsh.enable = true;
    password-store = {
      enable = true;
      package = config.lib.test.mkStubPackage {
        outPath = "@pass@";
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.zshrc
    assertFileContains \
      home-files/.zshrc \
      "source @pass@/share/zsh/site-functions/_pass"
  '';
}
