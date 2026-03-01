{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.rizin;
  eValueType = with lib.types; either str (either int (either bool float));
in
{
  meta.maintainers = [
    lib.hm.maintainers.rsahwe
  ];

  options = {
    programs.rizin = {
      enable = lib.mkEnableOption "Rizin";

      package = lib.mkPackageOption pkgs "rizin" { nullable = true; };

      settings = lib.mkOption {
        type = lib.types.attrsOf eValueType;
        default = { };
        example = {
          "asm.bytes" = true;
          "asm.bytes.space" = true;
        };
        description = ''
          Set of runtime configuration values written to the initial runcommands file.
          See <https://book.rizin.re/src/configuration/initial_scripts.html>
          for more information and use [](#opt-programs.rizin.extraConfig) to
          manually add commands.
        '';
      };

      extraConfig = lib.mkOption {
        type = lib.types.lines;
        default = "";
        example = ''
          e asm.bytes=true
          e asm.bytes.space=true
          b 0x100
        '';
        description = ''
          Extra run configuration written to {file}`rizinrc`.
          See <https://book.rizin.re/src/configuration/initial_scripts.html>
          for more information.
        '';
      };
    };
  };

  config =
    let
      configFile =
        if config.xdg.enable && config.home.preferXdgDirectories then
          "${config.xdg.configHome}/rizin/rizinrc"
        else
          ".rizinrc";
      configContent = ''
        # settings
        ${lib.concatStringsSep "\n" (lib.mapAttrsToList (k: v: "e ${k}=${lib.toString v}") cfg.settings)}

        # extraConfig
        ${cfg.extraConfig}
      '';
    in
    lib.mkIf cfg.enable {
      home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

      home.file.${configFile} = lib.mkIf ((cfg.extraConfig != "") || (cfg.settings != { })) {
        text = configContent;
      };
    };
}
