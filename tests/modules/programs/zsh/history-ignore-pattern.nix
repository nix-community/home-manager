{ config, lib, pkgs, ... }:

with lib;

{
  imports = [
    ({ ... }: { config.programs.zsh.history.ignorePatterns = [ "echo *" ]; })
    ({ ... }: { config.programs.zsh.history.ignorePatterns = [ "rm *" ]; })
  ];

  config = {
    programs.zsh.enable = true;

    test.stubs.zsh = { };

    nmt.script = ''
      assertFileContains home-files/.zshrc "HISTORY_IGNORE='(echo *|rm *)'"
    '';
  };
}
