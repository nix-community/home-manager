{ ... }:
{
  programs.feedr = {
    enable = true;
    settings = {
      network.http_timeout = 15;
    };
  };

  nmt.script = ''
    assertFileExists "home-files/.config/feedr/config.toml"
  '';
}
