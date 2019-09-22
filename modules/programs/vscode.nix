{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.vscode;
  dag = config.lib.dag;

  configFilePath =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "Library/Application Support/Code/User/settings.json"
    else
      "${config.xdg.configHome}/Code/User/settings.json";

in

{
  options = {
    programs.vscode = {
      enable = mkEnableOption "Visual Studio Code";
      
      package = mkOption {
        type = types.package;
        default = pkgs.vscode;
        example = literalExample "pkgs.vscodium";
        description = ''
          Version of Visual Studio Code to install
        '';
      };

      userSettings = mkOption {
        type = types.attrs;
        default = {};
        example = literalExample ''
          {
            "update.channel" = "none";
            "[nix]"."editor.tabSize" = 2;
          }
        '';
        description = ''
          Configuration written to Visual Studio Code's
          <filename>settings.json</filename>.
        '';
      };

      extensions = mkOption {
        type = types.listOf types.package;
        default = [];
        example = literalExample "[ pkgs.vscode-extensions.bbenoist.Nix ]";
        description = ''
          The extensions Visual Studio Code should be started with.
          These will override but not delete manually installed ones.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    home.file."${configFilePath}".text = builtins.toJSON cfg.userSettings;
    #adapted from https://discourse.nixos.org/t/vscode-extensions-setup/1801/2
    home.file =
      let
        toPaths = p: 
          mapAttrsToList (k: v: {''${k}''.source = p;}) (builtins.readDir p);
        toSymlink = concatMap (toPaths) cfg.extensions;
      in foldr (a: b: a//b) toSymlink;
  #   home.activation.vscExtensions = dag.entryAfter ["installPackages"] ''
  #       EXT_DIR=${config.home.homeDirectory}/.vscode/extensions
  #       $DRY_RUN_CMD mkdir -p $EXT_DIR
  #       for x in ${lib.concatMapStringsSep " " toString cfg.extensions}; do
  #           $DRY_RUN_CMD ln -s $x/share/vscode/extensions/* $EXT_DIR/
  #       done
  #   '';
  # };
}
