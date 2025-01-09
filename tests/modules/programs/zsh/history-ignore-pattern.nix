{ ... }:

{
  imports = [
    ./zsh-stubs.nix
    ({ ... }: { config.programs.zsh.history.ignorePatterns = [ "echo *" ]; })
    ({ ... }: { config.programs.zsh.history.ignorePatterns = [ "rm *" ]; })
  ];

  config = {
    programs.zsh.enable = true;

    nmt.script = ''
      assertFileContains home-files/.zshrc "HISTORY_IGNORE='(echo *|rm *)'"
    '';
  };
}
