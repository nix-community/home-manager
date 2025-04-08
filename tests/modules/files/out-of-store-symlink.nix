{ config, ... }:

let

  filePath = ./. + "/source with spaces!";

in
{
  home.file."oos".source = config.lib.file.mkOutOfStoreSymlink filePath;

  nmt.script = ''
    assertLinkExists "home-files/oos"

    storePath="$(readlink $TESTED/home-files/oos)"

    if [[ ! -L $storePath ]]; then
      fail "Expected $storePath to be a symbolic link, but it was not."
    fi

    actual="$(readlink "$storePath")"
    expected="${toString filePath}"
    if [[ $actual != $expected ]]; then
      fail "Symlink home-files/oos should point to $expected via the Nix store, but it actually points to $actual."
    fi
  '';
}
