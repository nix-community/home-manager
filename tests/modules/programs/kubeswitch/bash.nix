{
  programs = {
    kubeswitch.enable = true;
    bash.enable = true;
  };

  nmt.script = ''
    assertFileExists home-files/.bashrc
    assertFileRegex home-files/.bashrc \
      '^source /nix/store/[0-9a-z]*-kubeswitch-kswitch-shell-files-for-bash/share/kswitch_init.bash$'
    assertFileRegex home-files/.bashrc \
      '^source /nix/store/[0-9a-z]*-kubeswitch-kswitch-shell-files-for-bash/share/kswitch_completion.bash$'
  '';
}
