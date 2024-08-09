{ ... }: {
  programs.lazydocker.enable = true;

  nmt.script = ''
    assertFileExists home-files/.config/lazydocker/config.yml
    assertFileContent home-files/.config/lazydocker/config.yml \
      ${./default.yml}
  '';
}
