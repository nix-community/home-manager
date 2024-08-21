{ ... }: {
  programs = {
    asdf-vm = {
      enable = true;
      enableBashIntegration = false;
      enableFishIntegration = false;
      enableZshIntegration = false;
    };
    bash.enable = true;
    fish.enable = true;
    zsh.enable = true;
  };
  test.stubs.asdf-vm = { };
  nmt.script = ''
    assertFileNotRegex home-files/.bashrc '@asdf-vm@/share/asdf-vm/asdf.sh'
    assertFileNotRegex home-files/.bashrc '@asdf-vm@/share/asdf-vm/completions/asdf.bash'

    assertFileNotRegex home-files/.config/fish/config.fish '@asdf-vm@/share/asdf-vm/asdf.fish'

    assertFileNotRegex home-files/.zshrc '@asdf-vm@/share/asdf-vm/asdf.sh'
  '';
}
