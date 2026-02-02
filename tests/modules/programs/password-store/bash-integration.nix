{ config, ... }:
{
  programs = {
    bash.enable = true;
    password-store = {
      enable = true;
      package = config.lib.test.mkStubPackage {
        outPath = "@pass@";
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.bashrc
    assertFileContains \
      home-files/.bashrc \
      "source @pass@/share/bash-completion/completions/pass"
  '';
}
