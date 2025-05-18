{
  config,
  lib,
  pkgs,
  ...
}:
let

  cfg = config.programs.terminator;

  toValue =
    val:
    if val == null then
      "None"
    else if val == true then
      "True"
    else if val == false then
      "False"
    else
      ''"${toString val}"'';

  toConfigObject =
    let
      toKey = depth: key: if depth == 0 then key else toKey (depth - 1) "[${key}]";
      toConfigObjectLevel =
        depth: obj:
        lib.flatten (
          lib.mapAttrsToList (
            key: val:
            if lib.isAttrs val then
              [ (toKey depth key) ] ++ toConfigObjectLevel (depth + 1) val
            else
              [ "${key} = ${toValue val}" ]
          ) obj
        );
    in
    obj: lib.concatStringsSep "\n" (toConfigObjectLevel 1 obj);

in
{
  meta.maintainers = [ lib.maintainers.chisui ];

  options.programs.terminator = {
    enable = lib.mkEnableOption "terminator, a tiling terminal emulator";

    package = lib.mkPackageOption pkgs "terminator" { };

    config = lib.mkOption {
      default = { };
      description = ''
        configuration for terminator.

        For a list of all possible options refer to the
        {manpage}`terminator_config(5)`
        man page.
      '';
      type = lib.types.attrsOf lib.types.anything;
      example = lib.literalExpression ''
        {
          global_config.borderless = true;
          profiles.default.background_color = "#002b36";
        }
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "programs.terminator" pkgs lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    xdg.configFile."terminator/config" = lib.mkIf (cfg.config != { }) {
      text = toConfigObject cfg.config;
    };
  };
}
