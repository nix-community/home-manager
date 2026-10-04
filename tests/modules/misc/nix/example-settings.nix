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

  home.sessionSearchVariables.NIX_PATH = [ "/existing" ];

  nmt.script = ''
    assertFileContent \
      home-files/.config/nix/nix.conf \
      ${./example-settings-expected.conf}

    (
      export NIX_PATH=/inherited
      unset __HM_SESS_VARS_SOURCED __HM_SESS_VARS_MERGED
      . "$TESTED/home-path/etc/profile.d/hm-session-vars.sh"
      [ "$NIX_PATH" = "/existing:/a:/b/c:/inherited" ] \
        || { echo "NIX_PATH: $NIX_PATH"; exit 1; }
    ) || fail "nix.nixPath was not prepended to NIX_PATH"
  '';
}
