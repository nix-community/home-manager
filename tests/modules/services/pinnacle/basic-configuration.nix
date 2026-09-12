{ pkgs, realPkgs, ... }:
let
  inherit (realPkgs.pinnacle) src version cargoHash;
  buildRustConfig = realPkgs.pinnacle.buildRustConfig.override {
    libdisplay-info = realPkgs.libdisplay-info_0_3;
  };

  pinnacle-config = buildRustConfig {
    pname = "pinnacle-config";
    inherit version src cargoHash;

    buildAndTestSubdir = "api/rust";
    cargoBuildFlags = [
      "--example"
      "default_config"
    ];

    buildNoDefaultFeatures = true;
    buildFeatures = [ "snowcap" ];
    doCheck = false;
  };
in
{
  wayland.windowManager.pinnacle = {
    enable = true;
    clientPackage = pinnacle-config;
    systemd = {
      enable = true;
      xdgAutostart = true;
    };
    config.execCmd = [ "${pinnacle-config}/bin/default_config" ];
  };

  nmt.script =
    let
      expected = pkgs.writeText "expected.toml" ''
        run = ["${pinnacle-config}/bin/default_config"]
      '';
    in
    ''
      assertFileExists "home-files/.config/pinnacle/pinnacle.toml"
      assertFileContent "home-files/.config/pinnacle/pinnacle.toml" ${expected}
    '';
}
