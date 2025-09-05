{ ... }:

{
  programs = {
    kubeswitch.enable = true;
    fish.enable = true;
  };

  nmt.script = ''
    assertFileExists home-files/.config/fish/config.fish
    assertFileRegex home-files/.config/fish/config.fish \
      '^\s*source /nix/store/[0-9a-z]*-kubeswitch-kswitch-shell-files-for-fish/share/kswitch_init.fish$'
    assertFileRegex home-files/.config/fish/config.fish \
      '^\s*source /nix/store/[0-9a-z]*-kubeswitch-kswitch-shell-files-for-fish/share/kswitch_completion.fish$'
  '';
}
