modulePath:
{
  config,
  lib,
  realPkgs,
  ...
}:

let

  cfg = lib.getAttrFromPath modulePath config;

in
{
  test.stubs =
    let
      binaryName = lib.removeSuffix "-bin" cfg.wrappedPackageName;
      unwrappedName = "${cfg.wrappedPackageName}-unwrapped";
    in
    {
      "${unwrappedName}" = {
        name = unwrappedName;
        extraAttrs = {
          applicationName = cfg.darwinAppName;
          inherit binaryName;
          gtk3 = null;
          libName = cfg.wrappedPackageName;
          meta.description = "I pretend to be ${cfg.name}";
          meta.mainProgram = binaryName;
        };
        outPath = null;
        buildScript =
          if realPkgs.stdenv.hostPlatform.isDarwin then
            let
              darwinPath = "Applications/${cfg.darwinAppName}.app/Contents/MacOS";
            in
            ''
              echo BUILD
              mkdir -p "$out"/${darwinPath} "$out/Applications/${cfg.darwinAppName}.app/Contents/Resources"
              touch "$out/${darwinPath}/${binaryName}"
              chmod 755 "$out/${darwinPath}/${binaryName}"
            ''
          else
            ''
              echo BUILD
              mkdir -p "$out"/{bin,lib/${cfg.wrappedPackageName}}
              touch "$out/bin/${binaryName}"
              chmod 755 "$out/bin/${binaryName}"
            '';
      };

      chrome-gnome-shell = {
        buildScript = ''
          mkdir -p $out/lib/mozilla/native-messaging-hosts
          touch $out/lib/mozilla/native-messaging-hosts/dummy
        '';
      };
    };

  nixpkgs.overlays = [
    (_self: _super: {
      "${cfg.wrappedPackageName}" = realPkgs.wrapFirefox (config.lib.test.mkStubPackage
        config.test.stubs."${cfg.wrappedPackageName}-unwrapped"
      ) (lib.optionalAttrs (cfg.wrappedPackageName == "floorp-bin") { pname = "floorp-bin"; });
      inherit (realPkgs) mozlz4a;
    })
  ];
}
