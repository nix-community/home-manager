{ pkgs, ... }:

{
  programs = {
    worktrunk.enable = true;
    worktrunk.enableBashIntegration = true;
    bash.enable = true;
  };

  test.stubs.granted = { };

  nmt.script = ''
    assertFileExists home-files/.bashrc
    assertFileContains \
      home-files/.bashrc \
      'eval "$(@worktrunk@/bin/wt config shell init bash)"'
  '';
}
