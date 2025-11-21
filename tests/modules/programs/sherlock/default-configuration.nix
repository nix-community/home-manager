{
  programs.sherlock.enable = true;

  nmt.script = ''
    assertPathNotExists home-files/.config/sherlock/config.toml
    assertPathNotExists home-files/.config/sherlock/sherlock_alias.json
    assertPathNotExists home-files/.config/sherlock/fallback.json
    assertPathNotExists home-files/.config/sherlock/sherlockignore
    assertPathNotExists home-files/.config/sherlock/main.css
  '';
}
