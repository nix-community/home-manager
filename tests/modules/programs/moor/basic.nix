{ config, ... }:
{
  programs.moor = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "moor";
      outPath = "@moor@";
    };
    options = {
      no-linenumbers = true;
      no-search-line-highlight = true;
      no-statusbar = true;
      quit-if-one-screen = true;
      terminal-fg = true;
    };
  };

  nmt.script = ''
    assertFileContains home-path/etc/profile.d/hm-session-vars.sh \
      'MOOR="--no-linenumbers --no-search-line-highlight --no-statusbar --quit-if-one-screen --terminal-fg"'
    assertFileContains home-path/etc/profile.d/hm-session-vars.sh \
      'PAGER="@moor@/bin/moor"'
  '';
}
