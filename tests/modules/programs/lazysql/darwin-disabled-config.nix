{
  xdg.enable = false;
  xdg.configFile."lazysql/config.toml".enable = false;

  programs.lazysql = {
    enable = true;
    package = null;
    settings.application.DefaultPageSize = 300;
  };

  nmt.script = ''
    assertPathNotExists "home-files/Library/Application Support/lazysql/config.toml"
    assertPathNotExists home-files/.config/lazysql/config.toml
  '';
}
