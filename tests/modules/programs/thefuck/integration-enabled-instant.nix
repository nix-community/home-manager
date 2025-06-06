{ config, ... }:
{
  programs = {
    thefuck = {
      enable = true;
      package = config.lib.test.mkStubPackage { outPath = "@thefuck@"; };
      enableInstantMode = true;
    };
    bash.enable = true;
    zsh.enable = true;
  };

  nmt.script = ''
    assertFileExists home-files/.bashrc
    assertFileContains \
      home-files/.bashrc \
      'eval "$(@thefuck@/bin/thefuck --alias fuck --enable-experimental-instant-mode)"'

    assertFileExists home-files/.zshrc
    assertFileContains \
      home-files/.zshrc \
      'eval "$(@thefuck@/bin/thefuck --alias fuck --enable-experimental-instant-mode)"'
  '';
}
