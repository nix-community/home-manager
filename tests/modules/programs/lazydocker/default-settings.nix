{ ... }:
{
  programs.lazydocker.enable = true;
  test.stubs.lazydocker = { };
  nmt.script = ''
    assertFileExists home-files/.config/lazydocker/config.yml
    assertFileContent home-files/.config/lazydocker/config.yml \
      ${./default.yml}
  '';
}
