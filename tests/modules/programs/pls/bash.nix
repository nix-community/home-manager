{
  programs = {
    bash.enable = true;

    pls = {
      enable = true;
      enableAliases = true;
    };
  };

  nmt.script = ''
    assertFileExists home-files/.bashrc
    assertFileContains \
      home-files/.bashrc \
      "alias ls=@pls@/bin/pls"
    assertFileContains \
      home-files/.bashrc \
      "alias ll='@pls@/bin/pls -d perm -d user -d group -d size -d mtime -d git'"
  '';
}
