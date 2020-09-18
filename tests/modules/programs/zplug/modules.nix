{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.zsh = {
      enable = true;
      zplug = {
        enable = true;
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

    nixpkgs.overlays = [
      (self: super: {
        zsh = pkgs.writeScriptBin "dummy-zsh" "";
        zplug = pkgs.writeScriptBin "dummy-zplug" "";
      })
    ];

    nmt.script = ''
      assertFileRegex home-files/.zshrc \
        '^source ${builtins.storeDir}/.*zplug.*/init\.zsh$'

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
    '';
  };
}
