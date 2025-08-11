{
  programs.sherlock = {
    enable = true;
    package = null;
  };

  nmt.script = ''
    # With null package, no package should be installed
    assertPathNotExists home-path/bin/sherlock-launcher

    # With empty settings, no config files should be generated
    assertPathNotExists home-files/.config/sherlock/config.toml
    assertPathNotExists home-files/.config/sherlock/sherlock_alias.json
    assertPathNotExists home-files/.config/sherlock/fallback.json
    assertPathNotExists home-files/.config/sherlock/sherlockignore
    assertPathNotExists home-files/.config/sherlock/main.css
  '';
}
