{ config, lib, pkgs, realPkgs, ... }:

lib.mkIf config.test.enableBig {
  home.packages = [ pkgs.comic-relief ];

  fonts.fontconfig.enable = true;

  _module.args.pkgs = lib.mkForce realPkgs;

  nmt.script = ''
    assertDirectoryNotEmpty home-path/lib/fontconfig/cache
  '';
}
