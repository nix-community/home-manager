{ pkgs, config, lib, ... }:
let

  defaultHieNixSourceParams = {
    owner = "domenkozar";
    repo = "hie-nix";
    rev = "6794005f909600679d0b7894d0e7140985920775";
    sha256 = "0pc90ns0xcsa6b630d8kkq5zg8yzszbgd7qmnylkqpa0l58zvnpn";
  };
  defaultHieNixSource = pkgs.fetchFromGitHub defaultHieNixSourceParams;

  defaultHieNixExe = hie-nix.hies + "/bin/hie-wrapper";
  defaultHieNixExeText = ''hie-nix.hies + "/bin/hie-wrapper"'';

  inherit (pkgs.vscode-utils) buildVscodeMarketplaceExtension;
  inherit (lib) types;
  cfg = config.programs.vscode.haskell;

  hieNixArgs = lib.optionalAttrs (!cfg.hieNixUsePinnedPkgs) {
    inherit pkgs;
  };
  hie-nix = import cfg.hieNixSource hieNixArgs;

in
{
  options.programs.vscode.haskell.enable = lib.mkEnableOption "Haskell integration for Visual Studio Code";

  options.programs.vscode.haskell.hieNixSource = lib.mkOption {
    type = lib.types.path;
    default = defaultHieNixSource;
    defaultText = lib.literalExample ''
      pkgs.fetchFromGitHub
        ${lib.generators.toPretty {} defaultHieNixSourceParams}
    '';
    example = lib.literalExample ''
      ~/src/haskell-ide-engine
    '';
    description = ''
      A version of the <link xlink:href="https://github.com/domenkozar/hie-nix/">hie-nix sources</link>.
    '';
  };

  options.programs.vscode.haskell.hieExecutablePath = lib.mkOption {
    type = lib.types.path;
    default = defaultHieNixExe;
    defaultText = lib.literalExample defaultHieNixExeText;
    description = ''
      The path to the <code>hie</code> executable.
    '';
  };

  options.programs.vscode.haskell.hieNixUsePinnedPkgs = lib.mkOption {
    type = lib.types.bool;
    default = true;
    defaultText = lib.literalExample defaultHieNixExeText;
    description = ''
      Whether to use the nixpkgs pin in hie-nix to build hie-nix.

      By leaving this enabled, you can avoid building a very large set
      of Haskell packages. See
      <link xlink:href="https://hie-nix.cachix.org/">hie-nix.cachix.org</link>.
    '';
  };

  config = lib.mkIf cfg.enable {

    programs.vscode.userSettings = {
      "languageServerHaskell.enableHIE" = true;
      "languageServerHaskell.hieExecutablePath" =
        cfg.hieExecutablePath;
    };

    programs.vscode.extensions = [
      (pkgs.vscode-extensions.alanz.vscode-hie-server or
        (buildVscodeMarketplaceExtension {
          mktplcRef = {
            name = "vscode-hie-server";
            publisher = "alanz";
            version = "0.0.25";
            sha256 = "0m21w03v94qxm0i54ki5slh6rg7610zfxinfpngr0hfpgw2nnxvc";
          };
          meta = {
            license = pkgs.stdenv.lib.licenses.mit;
          };
        })
      )
      (pkgs.vscode-extensions.justusadam.language-haskell or
        (buildVscodeMarketplaceExtension {
          mktplcRef = {
            name = "language-haskell";
            publisher = "justusadam";
            version = "2.5.0";
            sha256 = "10jqj8qw5x6da9l8zhjbra3xcbrwb4cpwc3ygsy29mam5pd8g6b3";
          };
          meta = {
            license = pkgs.stdenv.lib.licenses.bsd3;
          };
        })
      )
    ];
  };
}
