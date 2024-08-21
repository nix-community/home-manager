{ ... }: {
  programs = {
    asdf-vm = {
      enable = true;
      enableBashIntegration = true;
      enableFishIntegration = true;
      enableZshIntegration = true;
    };
    bash.enable = true;
    fish.enable = true;
    zsh.enable = true;
  };
  test.stubs.asdf-vm = { };
  nmt.script = ''
    assertFileRegex home-files/.bashrc '@asdf-vm@/share/asdf-vm/asdf.sh'
    assertFileRegex home-files/.bashrc '@asdf-vm@/share/asdf-vm/completions/asdf.bash'

    assertFileRegex home-files/.config/fish/config.fish '@asdf-vm@/share/asdf-vm/asdf.fish'

    assertFileRegex home-files/.zshrc '@asdf-vm@/share/asdf-vm/asdf.sh'
  '';
}
