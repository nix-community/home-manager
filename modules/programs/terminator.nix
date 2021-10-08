{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.terminator;

  toValue = val:
    if val == null then
      "None"
    else if val == true then
      "True"
    else if val == false then
      "False"
    else
      ''"${toString val}"'';

  toConfigObject = let
    toKey = depth: key:
      if depth == 0 then key else toKey (depth - 1) "[${key}]";
    toConfigObjectLevel = depth: obj:
      flatten (mapAttrsToList (key: val:
        if isAttrs val then
          [ (toKey depth key) ] ++ toConfigObjectLevel (depth + 1) val
        else
          [ "${key} = ${toValue val}" ]) obj);
  in obj: concatStringsSep "\n" (toConfigObjectLevel 1 obj);

in {
  meta.maintainers = [ maintainers.chisui ];

  options.programs.terminator = {
    enable = mkEnableOption "terminator, a tiling terminal emulator";

    package = mkOption {
      type = types.package;
      default = pkgs.terminator;
      example = literalExpression "pkgs.terminator";
      description = "terminator package to install.";
    };

    config = mkOption {
      default = { };
      description = ''
        configuration for terminator.
        </para><para>
        For a list of all possible options refer to the
        <citerefentry>
          <refentrytitle>terminator_config</refentrytitle>
          <manvolnum>5</manvolnum>
        </citerefentry>
        man page.
      '';
      type = types.attrsOf types.anything;
      example = literalExpression ''
        {
          global_config.borderless = true;
          profiles.default.background_color = "#002b36";
        }
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (hm.assertions.assertPlatform "programs.terminator" pkgs platforms.linux)
    ];

    home.packages = [ cfg.package ];

    xdg.configFile."terminator/config" =
      mkIf (cfg.config != { }) { text = toConfigObject cfg.config; };
  };
}
