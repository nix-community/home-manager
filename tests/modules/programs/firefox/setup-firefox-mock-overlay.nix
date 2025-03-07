modulePath:
{ config, lib, realPkgs, ... }:

let

  cfg = lib.getAttrFromPath modulePath config;

in {
  test.stubs = let unwrappedName = "${cfg.wrappedPackageName}-unwrapped";
  in {
    "${unwrappedName}" = {
      name = unwrappedName;
      extraAttrs = {
        binaryName = cfg.wrappedPackageName;
        gtk3 = null;
        meta.description = "I pretend to be ${cfg.name}";
      };
      outPath = null;
      buildScript = ''
        echo BUILD
        mkdir -p "$out"/{bin,lib}
        touch "$out/bin/${cfg.wrappedPackageName}"
        chmod 755 "$out/bin/${cfg.wrappedPackageName}"
      '';
    };

    chrome-gnome-shell = {
      buildScript = ''
        mkdir -p $out/lib/mozilla/native-messaging-hosts
        touch $out/lib/mozilla/native-messaging-hosts/dummy
      '';
    };
  };

  nixpkgs.overlays = [ (_: _: { inherit (realPkgs) mozlz4a; }) ];
}
