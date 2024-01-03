{ pkgs, ... }:

let
  shellIntegration = ''
    def --env ya [args?] {
      let tmp = (mktemp -t "yazi-cwd.XXXXX")
      if ($args == null) {
        yazi --cwd-file $tmp
      } else {
        yazi $args --cwd-file $tmp
      }
      let cwd = (open $tmp)
      if $cwd != "" and $cwd != $env.PWD {
        cd $cwd
      }
      rm -f $tmp
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
    configPath = if pkgs.stdenv.isDarwin then
      "home-files/Library/Application Support/nushell/config.nu"
    else
      "home-files/.config/nushell/config.nu";
  in ''
    assertFileContains '${configPath}' '${shellIntegration}'
  '';
}
