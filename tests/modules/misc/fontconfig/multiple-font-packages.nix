{ pkgs, ... }: {
  config = {
    home.packages = [ pkgs.comic-relief pkgs.unifont ];

    fonts.fontconfig.enable = true;

    nmt.script = ''
      assertDirectoryNotEmpty home-path/lib/fontconfig/cache
    '';
  };
}
