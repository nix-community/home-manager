modulePath:
{
  config,
  lib,
  realPkgs,
  ...
}:

let

  cfg = lib.getAttrFromPath modulePath config;
  darwinPath = "Applications/${cfg.darwinAppName}.app/Contents/MacOS";

in
{
  test.stubs =
    let
      unwrappedName = "${cfg.wrappedPackageName}-unwrapped";
    in
    {
      "${unwrappedName}" = {
        name = unwrappedName;
        extraAttrs = {
          applicationName = cfg.wrappedPackageName;
          binaryName = cfg.wrappedPackageName;
          gtk3 = null;
          meta.description = "I pretend to be ${cfg.name}";
        };
        outPath = null;
        buildScript =
          if realPkgs.stdenv.hostPlatform.isDarwin then
            ''
              echo BUILD
              mkdir -p "$out"/${darwinPath}
              touch "$out/${darwinPath}/${cfg.wrappedPackageName}"
              chmod 755 "$out/${darwinPath}/${cfg.wrappedPackageName}"
            ''
          else
            ''
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
