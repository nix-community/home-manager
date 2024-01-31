{ config, ... }: {
  config = {
    programs.fish = {
      enable = true;

      shellAbbrs = {
        l = "less";
        gco = "git checkout";
        "-C" = {
          position = "anywhere";
          expansion = "--color";
        };
        L = {
          position = "anywhere";
          setCursor = true;
          expansion = "% | less";
        };
        "!!" = {
          position = "anywhere";
          function = "last_history_item";
        };
        vim_edit_texts = {
          position = "command";
          regex = ".+\\.txt";
          function = "vim_edit";
        };
        "4DIRS" = {
          setCursor = "!";
          expansion = ''
            for dir in */
              cd $dir
              !
              cd ..
            end
          '';
        };
        dotdot = {
          regex = "^\\.\\.+$";
          function = "multicd";
        };
      };
    };

    nmt = {
      description =
        "if fish.shellAbbrs is set, check fish.config contains valid abbreviations";
      script = ''
        assertFileContains home-files/.config/fish/config.fish \
          "abbr --add -- l less"
        assertFileContains home-files/.config/fish/config.fish \
          "abbr --add -- gco 'git checkout'"
        assertFileContains home-files/.config/fish/config.fish \
          "abbr --add --position anywhere -- -C --color"
        assertFileContains home-files/.config/fish/config.fish \
          "abbr --add --position anywhere --set-cursor -- L '% | less'"
        assertFileContains home-files/.config/fish/config.fish \
          "abbr --add --function last_history_item --position anywhere -- !!"
        assertFileContains home-files/.config/fish/config.fish \
          "abbr --add --function vim_edit --position command --regex '.+\.txt' -- vim_edit_texts"
        assertFileContains home-files/.config/fish/config.fish \
          "abbr --add '--set-cursor=!' -- 4DIRS 'for dir in */
          cd \$dir
          !
          cd ..
        end
        '"
        assertFileContains home-files/.config/fish/config.fish \
          "abbr --add --function multicd --regex '^\.\.+$' -- dotdot"
      '';
    };
  };
}
