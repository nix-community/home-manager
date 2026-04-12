{ pkgs, ... }:

{
  programs = {
    worktrunk.enable = true;
    worktrunk.enableBashIntegration = false;
    bash.enable = true;
  };

  test.stubs.worktrunk = { };

  nmt.script = ''
    assertFileExists home-files/.bashrc
    assertFileNotRegex \
      home-files/.bashrc \
      'eval "$(@worktrunk@/bin/wt config shell init bash)"'
  '';
}
