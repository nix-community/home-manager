{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.vscode;

  vscodePname = cfg.package.pname;

  configDir = {
    "vscode" = "Code";
    "vscode-insiders" = "Code - Insiders";
    "vscodium" = "Codium";
  }.${vscodePname};

  configFilePath =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "Library/Application Support/${configDir}/User/settings.json"
    else
      "${config.xdg.configHome}/${configDir}/User/settings.json";

  # TODO: On Darwin where are the extensions?
  extensionPath = ".${vscodePname}/extensions";
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
          Version of Visual Studio Code to install.
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

    # Adapted from https://discourse.nixos.org/t/vscode-extensions-setup/1801/2
    home.file =
      let
        toPaths = p:
          # Links every dir in p to the extension path.
          mapAttrsToList (k: v:
            {
              "${extensionPath}/${k}".source = "${p}/${k}";
            }) (builtins.readDir p);
        toSymlink = concatMap toPaths cfg.extensions;
      in
        foldr
          (a: b: a // b)
          {
            "${configFilePath}".text = builtins.toJSON cfg.userSettings;
          }
          toSymlink;
  };
}
