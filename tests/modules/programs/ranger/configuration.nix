{
  programs.ranger = {
    enable = true;
    package = null;
    settings = {
      column_ratios = "1,3,3";
      confirm_on_delete = "never";
      unicode_ellipsis = true;
      scroll_offset = 8;
    };
    aliases = {
      e = "edit";
      setl = "setlocal";
      filter = "scout -prts";
    };
    mappings = {
      Q = "quitall";
      q = "quit";
    };
    extraConfig = "unmap gd";
    rifle = [
      {
        condition = "mime ^text, label editor";
        command = ''vim -- "$@"'';
      }
      {
        condition = "mime ^text, label pager";
        command = ''less -- "$@"'';
      }
    ];
  };

  nmt.script = ''
    assertFileExists home-files/.config/ranger/rc.conf
    assertFileContent home-files/.config/ranger/rc.conf \
      ${./configuration-rc.conf}

    assertFileExists home-files/.config/ranger/rifle.conf
    assertFileContent home-files/.config/ranger/rifle.conf \
      ${./configuration-rifle.conf}
  '';
}
