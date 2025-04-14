{ pkgs, ... }:
{
  programs.bash.enable = true;
  programs.direnv = {
    enable = true;
    silent = true;
  };

  nmt.script = ''
    assertFileExists home-files/.config/direnv/direnv.toml
    assertFileContent \
      home-files/.config/direnv/direnv.toml \
      ${pkgs.writeText "direnv.toml" ''
        [global]
        log_filter = "^$"
        log_format = "-"
      ''}
  '';
}
