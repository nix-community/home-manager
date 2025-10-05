{ pkgs, ... }:

{
  programs.intelli-shell = {
    enable = true;
    settings = {
      data_dir = "/home/myuser/my/custom/datadir";
      check_updates = false;
      logs.enabled = false;
      theme = {
        primary = "default";
        secondary = "dim";
        accent = "yellow";
        comment = "italic green";
        error = "dark red";
        highlight = "darkgrey";
        highlight_symbol = "» ";
        highlight_primary = "default";
        highlight_secondary = "default";
        highlight_accent = "yellow";
        highlight_comment = "italic green";
      };
    };
  };

  nmt.script =
    let
      configPath =
        if pkgs.stdenv.hostPlatform.isDarwin then
          "Library/Preferences/org.IntelliShell.Intelli-Shell"
        else
          ".config/intelli-shell";
    in
    ''
      assertFileExists home-files/${configPath}/config.toml
      assertFileContent home-files/${configPath}/config.toml \
        ${./config.toml}
    '';
}
