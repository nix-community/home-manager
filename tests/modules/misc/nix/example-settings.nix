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

      nixPath = [ "/a" "/b/c" ];

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

      assertFileContains home-path/etc/profile.d/hm-session-vars.sh \
        'export NIX_PATH="/a:/b/c''${NIX_PATH:+:$NIX_PATH}"'
    '';
  };
}
