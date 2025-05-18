{ pkgs, ... }:
{
  programs.television = {
    enable = true;
    settings = {
      tick_rate = 50;
      ui = {
        use_nerd_font_icons = false;
        show_preview_panel = true;
        input_bar_position = "top";
      };
    };
    channels.my-custom = {
      cable_channel = [
        {
          name = "git-log";
          source_command = ''git log --oneline --date=short --pretty="format:%h %s %an %cd" "$@"'';
          preview_command = "git show -p --stat --pretty=fuller --color=always {0}";
        }
        {
          name = "my-dotfiles";
          source_command = "fd -t f . $HOME/.config";
          preview_command = "bat -n --color=always {0}";
        }
      ];
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/television/config.toml
    assertFileContent home-files/.config/television/config.toml \
      ${pkgs.writeText "settings-expected" ''
        tick_rate = 50

        [ui]
        input_bar_position = "top"
        show_preview_panel = true
        use_nerd_font_icons = false
      ''}
    assertFileExists home-files/.config/television/my-custom-channels.toml
    assertFileContent home-files/.config/television/my-custom-channels.toml \
      ${pkgs.writeText "channels-expected" ''
        [[cable_channel]]
        name = "git-log"
        preview_command = "git show -p --stat --pretty=fuller --color=always {0}"
        source_command = "git log --oneline --date=short --pretty=\"format:%h %s %an %cd\" \"$@\""

        [[cable_channel]]
        name = "my-dotfiles"
        preview_command = "bat -n --color=always {0}"
        source_command = "fd -t f . $HOME/.config"
      ''}
  '';
}
