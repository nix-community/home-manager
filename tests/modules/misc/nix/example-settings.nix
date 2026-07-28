{
  config,
  lib,
  pkgs,
  ...
}:

{
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

    nixPath = [
      "/a"
      "/b/c"
    ];

    settings = {
      sandbox = true;
      show-trace = true;
      system-features = [
        "big-parallel"
        "kvm"
        "recursive-nix"
      ];
    };
  };

  nmt.script = ''
    assertFileContent \
      home-files/.config/nix/nix.conf \
      ${./example-settings-expected.conf}

    (
      export NIX_PATH=/inherited
      . "$TESTED/home-path/etc/profile.d/hm-session-vars.sh"
      [ "$NIX_PATH" = "/a:/b/c:/inherited" ]
    ) || fail "configured NIX_PATH was not prepended"
  '';
}
