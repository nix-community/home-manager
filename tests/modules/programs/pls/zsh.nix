{ config, ... }:

{
  programs = {
    zsh.enable = true;

    pls = {
      enable = true;
      enableAliases = true;
      package = config.lib.test.mkStubPackage { outPath = "@pls@"; };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.zshrc
    assertFileContains \
      home-files/.zshrc \
      "alias -- ls=@pls@/bin/pls"
    assertFileContains \
      home-files/.zshrc \
      "alias -- ll='@pls@/bin/pls -d perm -d user -d group -d size -d mtime -d git'"
  '';
}
