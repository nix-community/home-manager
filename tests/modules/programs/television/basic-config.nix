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
    channels.git-log = {
      metadata = {
        name = "git-log";
        description = "A channel to select from git log entries";
        requirements = [ "git" ];
      };
      source = {
        command = "git log --oneline --date=short --pretty=\"format:%h %s %an %cd\" \"$@\"";
        output = "{split: :0}";
      };
      preview = {
        command = "git show -p --stat --pretty=fuller --color=always '{0}'";
      };
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
    assertFileExists home-files/.config/television/cable/git-log.toml
    assertFileContent home-files/.config/television/cable/git-log.toml \
      ${pkgs.writeText "channels-expected" ''
        [metadata]
        description = "A channel to select from git log entries"
        name = "git-log"
        requirements = ["git"]

        [preview]
        command = "git show -p --stat --pretty=fuller --color=always '{0}'"

        [source]
        command = "git log --oneline --date=short --pretty=\"format:%h %s %an %cd\" \"$@\""
        output = "{split: :0}"
      ''}
  '';
}
