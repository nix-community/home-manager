{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    nix = {
      package = config.lib.test.mkStubPackage {
        version = lib.getVersion pkgs.nixVersions.stable;
        buildScript = ''
          target=$out/bin/nix
          mkdir -p "$(dirname "$target")"

          echo -n "true" > "$target"

          chmod +x "$target"
        '';
      };

      settings = {
        use-sandbox = true;
        show-trace = true;
        system-features = [ "big-parallel" "kvm" "recursive-nix" ];
      };
    };

    nmt.script = ''
      assertFileContent \
        home-files/.config/nix/nix.conf \
        ${./example-settings-expected.conf}
    '';
  };
}
