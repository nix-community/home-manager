{ config, pkgs, ... }:
let
  hmPkgs = pkgs.extend (
    self: super: {
      aerospace = config.lib.test.mkStubPackage {
        name = "aerospace";
        buildScript = ''
          mkdir -p $out/bin
          touch $out/bin/aerospace
          chmod 755 $out/bin/aerospace
        '';
      };
    }
  );
in
{
  xdg.enable = false;

  programs.aerospace = {
    enable = true;
    package = hmPkgs.aerospace;
  };

  nmt.script = ''
    # aerospace just create the config file if we open it by hand, otherwise he's use directly the default config
    assertPathNotExists "home-files/.aerospace.toml"
  '';
}
