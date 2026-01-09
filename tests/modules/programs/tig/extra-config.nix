{ ... }:

{
  programs.tig = {
    enable = true;
    settings = {
      mouse = true;
    };
    extraConfig = ''
      # Custom key bindings for git workflow
      bind main R !git rebase -i %(commit)^
      bind main F !git fetch
    '';
  };

  nmt.script = ''
    assertFileExists home-files/.config/tig/config
    assertFileContent home-files/.config/tig/config \
      ${./extra-config-expected.conf}
  '';
}
