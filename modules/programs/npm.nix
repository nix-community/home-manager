# https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/programs/npm.nix
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.npm;

  xdgConfigHome = lib.removePrefix config.home.homeDirectory config.xdg.configHome;
  configFile = if config.home.preferXdgDirectories then "${xdgConfigHome}/npm/npmrc" else ".npmrc";

  iniFormat = pkgs.formats.ini {
    listsAsDuplicateKeys = true;
  };

  toNpmrc =
    let
      mkLine = lib.generators.mkKeyValueDefault { } "=";
      mkLines = k: v: if lib.isList v then map (x: mkLine "${k}[]" x) v else [ (mkLine k v) ];
    in
    attrs: lib.concatLines (lib.concatLists (lib.mapAttrsToList mkLines attrs));
in
{
  meta.maintainers = with lib.maintainers; [ mirkolenz ];

  options = {
    programs.npm = {
      enable = lib.mkEnableOption "{command}`npm` user config";

      package = lib.mkPackageOption pkgs [ "nodejs" ] {
        example = "nodejs_24";
        nullable = true;
      };

      settings = lib.mkOption {
        type = lib.types.attrsOf iniFormat.lib.types.atom;
        description = ''
          The user-specific npm configuration.
          See <https://docs.npmjs.com/cli/using-npm/config> and
          <https://docs.npmjs.com/cli/configuring-npm/npmrc>
          for more information.
        '';
        default = {
          prefix = "\${HOME}/.npm";
        };
        example = lib.literalExpression ''
          {
            color = true;
            include = [
              "dev"
              "prod"
            ];
            init-license = "MIT";
            prefix = "''${HOME}/.npm";
          }
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home = {
      packages = lib.mkIf (cfg.package != null) [ cfg.package ];
      file.${configFile} = lib.mkIf (cfg.settings != { }) {
        text = toNpmrc cfg.settings;
      };
      sessionVariables = lib.mkIf (cfg.settings != { }) {
        NPM_CONFIG_USERCONFIG = "${config.home.homeDirectory}/${configFile}";
      };
    };
  };
}
