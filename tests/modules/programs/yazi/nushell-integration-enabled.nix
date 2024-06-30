{ pkgs, config, ... }:

let
  shellIntegration = ''
    def --env yy [...args] {
      let tmp = (mktemp -t "yazi-cwd.XXXXX")
      yazi ...$args --cwd-file $tmp
      let cwd = (open $tmp)
      if $cwd != "" and $cwd != $env.PWD {
        cd $cwd
      }
      rm -fp $tmp
    }
  '';
in {
  programs.nushell.enable = true;

  programs.yazi = {
    enable = true;
    enableNushellIntegration = true;
  };

  test.stubs.yazi = { };

  nmt.script = let
    configPath = if pkgs.stdenv.isDarwin && !config.xdg.enable then
      "home-files/Library/Application Support/nushell/config.nu"
    else
      "home-files/.config/nushell/config.nu";
  in ''
    assertFileContains '${configPath}' '${shellIntegration}'
  '';
}
