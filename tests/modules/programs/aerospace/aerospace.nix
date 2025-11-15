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
  programs.aerospace = {
    enable = true;
    package = hmPkgs.aerospace;
  };

  nmt.script = ''
    assertFileExists "home-files/.config/aerospace/aerospace.toml"
    assertFileContent "home-files/.config/aerospace/aerospace.toml" ${./aerospace-expected.toml}
  '';
}
