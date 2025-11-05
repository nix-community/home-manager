{
  forkInputs,
  lib,
  pkgs,
  ...
}@inputs:
let
  inherit (import ./test-helpers.nix inputs) mkVSCodeExtension userDirectory;

  hie-nix-mock-package =
    pkgs.runCommand "hie-nix" { } ''
      mkdir -p $out
    ''
    // {
      hies = pkgs.runCommand "hie-nix-hies" { } ''
        mkdir -p $out/bin
        touch $out/bin/hie-wrapper
        chmod +x $out/bin/hie-wrapper
      '';
    };

  hieServerId = "alanz.vscode-hie-server";
  languageHaskellId = "justusadam.language-haskell";

  hieServerExtension = mkVSCodeExtension "vscode-hie-server" hieServerId {
    version = "0.0.1";
    vscodeExtUniqueId = hieServerId;
    vscodeExtPublisher = "alanz";
  };

  haskellExtension = mkVSCodeExtension "language-haskell" languageHaskellId {
    version = "0.0.1";
    vscodeExtUniqueId = languageHaskellId;
    vscodeExtPublisher = "justusadam";
  };

  expectedHaskellSettings = pkgs.writeText "expected-haskell-settings.json" ''
    {
      "languageServerHaskell.enableHIE": true,
      "languageServerHaskell.hieExecutablePath": "${hie-nix-mock-package.hies}/bin/hie-wrapper"
    }
  '';

  forkConfig = forkInputs // {
    haskell = {
      enable = true;
      hie.enable = true;
    };
  };
in
{
  config = lib.setAttrByPath [ "programs" forkInputs.moduleName ] forkConfig // {
    nixpkgs.overlays = [
      (self: super: {
        hie-nix = hie-nix-mock-package;

        vscode-extensions = super.vscode-extensions or { } // {
          justusadam = super.vscode-extensions.justusadam or { } // {
            language-haskell = haskellExtension;
          };
          alanz = super.vscode-extensions.alanz or { } // {
            vscode-hie-server = hieServerExtension;
          };
        };
      })
    ];

    nmt.script = ''
      assertDirectoryExists "home-files/${userDirectory}"
      assertDirectoryExists "home-files/.vscode/extensions"

      assertFileExists "home-files/${userDirectory}/.immutable-settings.json"
      assertFileContent "home-files/${userDirectory}/.immutable-settings.json" "${builtins.toJSON expectedHaskellSettings}"

      assertDirectoryExists "home-files/.vscode/extensions/${hieServerId}"
      assertDirectoryExists "home-files/.vscode/extensions/${languageHaskellId}"

      assertLinkExists "home-files/.vscode/extensions/${hieServerId}"
      assertLinkExists "home-files/.vscode/extensions/${languageHaskellId}"

      assertLinkPointsTo "home-files/.vscode/extensions/${hieServerId}" "${hieServerExtension}/share/vscode/extensions/${hieServerId}"
      assertLinkPointsTo "home-files/.vscode/extensions/${languageHaskellId}" "${haskellExtension}/share/vscode/extensions/${languageHaskellId}"

      assertFileExists "home-files/.vscode/extensions/${hieServerId}/.placeholder"
      assertFileExists "home-files/.vscode/extensions/${languageHaskellId}/.placeholder"
    '';
  };
}
