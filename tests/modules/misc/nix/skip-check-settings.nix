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

    extraOptions = ''
      some! nonsense {
        which should fail validation
    '';
    checkConfig = false;
  };

  nmt.script = ''
    assertFileContent \
      home-files/.config/nix/nix.conf \
      ${./skip-check-settings-expected.conf}
  '';
}
