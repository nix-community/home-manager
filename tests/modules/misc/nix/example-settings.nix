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

    assertFileContains home-path/etc/profile.d/hm-session-vars.sh \
      '__hm_entry="/a"'
    assertFileContains home-path/etc/profile.d/hm-session-vars.sh \
      '__hm_entry="/b/c"'
    assertFileContains home-path/etc/profile.d/hm-session-vars.sh \
      '__hm_cur="''${NIX_PATH-}"'
    # Each value must be prepended, not appended. Checked inside that
    # variable's own merge block: on Darwin the terminfo fallback adds a
    # genuine append block elsewhere in the same file.
    grep -B 3 -F 'export NIX_PATH="$__hm_cur"' "$TESTED/home-path/etc/profile.d/hm-session-vars.sh" \
      | grep -qF '__hm_cur="$__hm_add' \
      || fail 'NIX_PATH must be prepended, not appended'
  '';
}
