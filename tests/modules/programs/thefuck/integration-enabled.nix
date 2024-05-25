{ ... }:

{
  programs = {
    thefuck.enable = true;
    bash.enable = true;
    fish.enable = true;
    zsh.enable = true;
    nushell.enable = true;
  };

  test.stubs.thefuck = { };

  nmt.script = ''
    assertFileExists home-files/.bashrc
    assertFileContains \
      home-files/.bashrc \
      'eval "$(@thefuck@/bin/thefuck '"'"'--alias'"'"')"'

    assertFileExists home-files/.config/fish/functions/fuck.fish
    assertFileContains \
      home-files/.config/fish/functions/fuck.fish \
      'function fuck --description="Correct your previous console command"
          set -l fucked_up_command $history[1]
          env TF_SHELL=fish TF_ALIAS=fuck PYTHONIOENCODING=utf-8 @thefuck@/bin/thefuck $fucked_up_command THEFUCK_ARGUMENT_PLACEHOLDER $argv | read -l unfucked_command
          if [ "$unfucked_command" != "" ]
              eval $unfucked_command
              builtin history delete --exact --case-sensitive -- $fucked_up_command
              builtin history merge
          end
      end'

    assertFileExists home-files/.zshrc
    assertFileContains \
      home-files/.zshrc \
      'eval "$(@thefuck@/bin/thefuck '"'"'--alias'"'"')"'

    assertFileExists home-files/.config/nushell/config.nu
    assertFileContains \
      home-files/.config/nushell/config.nu \
      'alias fuck = @thefuck@/bin/thefuck $"(history | last 1 | get command | get 0)"'
  '';
}
