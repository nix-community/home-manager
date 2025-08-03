{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.vscode-profiles;
in
{
  options = {
    programs.vscode-profiles = {
      enable = lib.mkEnableOption "VSCode profiles extension";
      package = lib.mkPackageOption pkgs "hello" { };

      profiles = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.submodule {
            options = {
              extensions = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                description = "VSCode extensions";
              };

              keybindings = lib.mkOption {
                type = lib.types.listOf lib.types.attrs;
                description = "VSCode keybindings";
              };

              settings = lib.mkOption {
                type = lib.types.attrs;
                description = "VSCode settings";
              };
            };
          }
        );
        default = { };
        description = "VSCode profiles configuration";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    home.file = lib.mkMerge (
      lib.mapAttrsToList (profile: profileConfig: {
        "${config.xdg.configHome}/vscode-profiles/${profile}.json" = {
          text = builtins.toJSON profileConfig.settings;
        };
      }) cfg.profiles
    );

    # Keep our test activation
    home.activation.testVscodeProfiles = ''
      echo "VSCode profiles module loaded successfully!"
      echo "Configured profiles: ${lib.concatStringsSep ", " (lib.attrNames cfg.profiles)}"
    '';
  };
}
