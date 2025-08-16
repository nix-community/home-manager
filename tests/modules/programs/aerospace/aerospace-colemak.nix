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

    userSettings = {
      gaps = {
        outer.left = 8;
        outer.bottom = 8;
        outer.top = 8;
        outer.right = 8;
      };
      mode.main.binding = {
        alt-h = "focus left";
        alt-j = "focus down";
        alt-k = "focus up";
        alt-l = "focus right";
      };
      key-mapping.preset = "colemak";
    };
  };

  nmt.script = ''
    assertFileContent home-files/.config/aerospace/aerospace.toml ${./colemak-settings-expected.toml}
  '';
}
