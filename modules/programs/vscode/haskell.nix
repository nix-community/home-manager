{ pkgs, config, lib, ... }:
let

  inherit (pkgs.vscode-utils) buildVscodeMarketplaceExtension;
  inherit (lib) types;
  cfg = config.programs.vscode.haskell;

  defaultHieNixExe = hie-nix.hies + "/bin/hie-wrapper";
  defaultHieNixExeText = ''pkgs.hie-nix.hies + "/bin/hie-wrapper"'';

  hie-nix = pkgs.hie-nix or (abort ''
    pkgs.hie-nix was not found. Please add an overlay like the following:
    ${exampleOverlay}
  '');

  exampleOverlay = ''
    nixpkgs.overlays = [ (self: super: {
      hie-nix = import ~/src/hie-nix {};
    ];
  '';

in
{
  options.programs.vscode.haskell.enable = lib.mkEnableOption "Haskell integration for Visual Studio Code";

  options.programs.vscode.haskell.hie.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Enable Haskell IDE engine integration";
  };

  options.programs.vscode.haskell.hie.executablePath = lib.mkOption {
    type = lib.types.path;
    default = defaultHieNixExe;
    defaultText = lib.literalExample defaultHieNixExeText;
    description = ''
      The path to the Haskell IDE Engine executable.

      Because hie-nix is not packaged in Nixpkgs, you need to add it as an
      overlay or set this option. Example overlay configuration:

      <code>${exampleOverlay}</code>
    '';
    example = lib.literalExample ''
      # First, run cachix use hie-nix
      (import ~/src/haskell-ide-engine {}).hies + "/bin/hie-wrapper";
    '';

  };

  config = lib.mkIf cfg.enable {

    programs.vscode.userSettings = lib.mkIf cfg.hie.enable {
      "languageServerHaskell.enableHIE" = true;
      "languageServerHaskell.hieExecutablePath" =
        cfg.hie.executablePath;
    };

    programs.vscode.extensions = [
        pkgs.vscode-extensions.justusadam.language-haskell
      ] ++
      lib.optional cfg.hie.enable
        pkgs.vscode-extensions.alanz.vscode-hie-server
    ;
  };
}
