{
  programs.gh = {
    enable = true;
    settings.aliases = { co = "pr checkout"; };
    settings.editor = "vim";
  };

  nmt.script = ''
    assertFileExists home-files/.config/gh/config.yml
    assertFileContent home-files/.config/gh/config.yml ${
      builtins.toFile "config-file.yml" ''
        aliases:
          co: pr checkout
        editor: vim
        git_protocol: https
        version: '1'
      ''
    }
  '';
}
