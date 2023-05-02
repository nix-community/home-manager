{ config, pkgs, options, user, lib, ... }:

with lib;
with lib.strings;
let
  cfg = config.programs.rcm;

  quotedList = l: ''"${concatStringsSep " " l}"'';
  toConfigFile = generators.toKeyValue {
    mkKeyValue = k: v:
      "${toUpper k}=${if isList v then quotedList v else quotedList [ v ]}";
    listsAsDuplicateKeys = false;
  };
in {
  options = {
    programs.rcm = {
      enable = mkEnableOption "rcm";
      rcrc = mkOption {
        type = types.path;
        default = ".rcrc";
        description = lib.mdDoc ''
          Location of the RCRC file relative to the users home directory.
        '';
        example = ".config/rcm/rcrc";
      };
      settings = mkOption {
        type = with types; attrsOf (either str (listOf str));
        default = { };
        description = lib.mdDoc ''
          Submodule defining the .rcrc file. Mapping of the key value pairs for rcms config.
        '';
      };
    };
  };
  config = mkIf cfg.enable {
    home.packages = with pkgs; [ rcm ];
    home.file.${cfg.rcrc} = { text = toConfigFile cfg.settings; };
    home.sessionVariables = lib.mkIf cfg.rcrc != options.programs.rcm.rcrc.default {
      RCRC = "${config.home.homeDirectory}/${cfg.rcrc}";
    };
  };

  meta.maintainers = [ maintainers.SpringerJack ];
}
