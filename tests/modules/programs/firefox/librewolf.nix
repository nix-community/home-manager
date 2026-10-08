{ lib, ... }:
let
  tests = import ./common.nix {
    inherit lib;
    name = "librewolf";
  };
in
lib.mapAttrs (
  _: test:
  { config, pkgs, ... }:
  let
    librewolfUnwrapped = config.lib.test.mkStubPackage {
      name = "browser-unwrapped-test-stub";
      extraAttrs = {
        applicationName = "librewolf";
        binaryName = "librewolf";
        gtk3 = null;
        libName = "librewolf";
        meta.description = "I pretend to be LibreWolf";
        meta.mainProgram = "librewolf";
      };
      outPath = null;
    };

    mkLibrewolf = lib.makeOverridable (
      {
        cfg ? { },
        extraPolicies ? { },
        pkcs11Modules ? [ ],
      }:
      config.lib.test.mkStubPackage {
        name = "browser-test-stub";
        buildScript =
          let
            policiesJson = pkgs.writeText "policies.json" (
              builtins.seq cfg (
                builtins.seq pkcs11Modules (
                  builtins.toJSON {
                    policies = config.programs.librewolf.policies // extraPolicies // { DownloadDirectory = "/foo"; };
                  }
                )
              )
            );
          in
          ''
            mkdir -p "$out/bin"
            mkdir -p "$out/lib/librewolf/distribution"
            mkdir -p "$out/Applications/Librewolf.app/Contents/MacOS"
            mkdir -p "$out/Applications/Librewolf.app/Contents/Resources/distribution"

            cat > "$out/bin/librewolf" <<'EOF'
            MOZ_APP_LAUNCHER=
            EOF
            chmod 755 "$out/bin/librewolf"

            cp "$out/bin/librewolf" "$out/Applications/Librewolf.app/Contents/MacOS/librewolf"
            cp ${policiesJson} "$out/lib/librewolf/distribution/policies.json"
            cp ${policiesJson} "$out/Applications/Librewolf.app/Contents/Resources/distribution/policies.json"
          '';
        extraAttrs = {
          browserName = "librewolf";
          meta.mainProgram = "librewolf";
          unwrapped = librewolfUnwrapped;
        };
      }
    ) { };
  in
  {
    imports = [ test ];

    # Librewolf is insecure in nixpkgs; use a small wrapper-shaped package and
    # skip its generated native messaging host join so module tests do not
    # evaluate or build the real browser closure.
    nixpkgs.overlays = [
      (_: _: {
        librewolf = mkLibrewolf;
        librewolf-unwrapped = librewolfUnwrapped;
      })
    ];
    mozilla.librewolfNativeMessagingHosts = lib.mkForce [ ];
    programs.librewolf.package = lib.mkDefault mkLibrewolf;
  }
) tests
