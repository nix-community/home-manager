{
  programs = {
    kubeswitch.enable = true;
    zsh.enable = true;
  };

  nmt.script = ''
    assertFileExists home-files/.zshrc
    assertFileRegex home-files/.zshrc \
      '^source /nix/store/[0-9a-z]*-kubeswitch-shell-files/share/kswitch_init.zsh$'
    assertFileRegex home-files/.zshrc \
      '^source /nix/store/[0-9a-z]*-kubeswitch-shell-files/share/kswitch_completion.zsh$'
  '';
}
