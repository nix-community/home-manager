{ config, lib, pkgs, ... }:

with lib;

{
  programs.bash.enable = true;

  test.stubs.bash-completion = { };

  nmt.script = ''
    assertFileExists home-files/.bashrc

    assertFileContains \
      home-files/.bashrc \
      'if [[ ! -v BASH_COMPLETION_VERSINFO ]]; then'
    assertFileContains \
      home-files/.bashrc \
      '  . "@bash-completion@/etc/profile.d/bash_completion.sh"'
    assertFileContains \
      home-files/.bashrc \
      'fi'
  '';
}
