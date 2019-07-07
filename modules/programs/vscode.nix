{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.vscode;

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
    home.packages = [
      (pkgs.vscode-with-extensions.override {
        vscodeExtensions = cfg.extensions;
      })
    ];

    home.file."${configFilePath}".text = builtins.toJSON cfg.userSettings;
  };
}
