{ config, pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    zplug = {
      enable = true;
      zplugHome = pkgs.emptyDirectory;
      plugins = [
        {
          name = "plugins/git";
          tags = [ "from:oh-my-zsh" ];
        }
        {
          name = "lib/clipboard";
          tags = [ "from:oh-my-zsh" ''if:"[[ $OSTYPE == *darwin* ]]"'' ];
        }
      ];
    };
  };

  nmt.script = ''
    assertFileContains home-files/.zshrc \
      'source @zplug@/share/zplug/init.zsh'

    assertFileContains home-files/.zshrc \
      'zplug "plugins/git", from:oh-my-zsh'

    assertFileContains home-files/.zshrc \
      'zplug "lib/clipboard", from:oh-my-zsh, if:"[[ $OSTYPE == *darwin* ]]"'

    assertFileContains home-files/.zshrc \
      'if ! zplug check; then
         zplug install
       fi'

    assertFileRegex home-files/.zshrc \
      '^zplug load$'

    assertFileContains home-files/.zshrc \
      'export ZPLUG_HOME=${config.programs.zsh.zplug.zplugHome}'
  '';
}
