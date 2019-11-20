{ config, lib, pkgs, ... }:

with lib;

let
  xComposeType = with types; either (attrsOf xComposeType) str;

  cfg = config.xsession.xCompose;

  xComposeGen = (
    dic: s: lib.mapAttrs
      (
        n: v:
          if
            (builtins.isString v)
          then
            ''${s}<${n}> : "${v}"''
          else
            (xComposeGen v (''${s}<${n}> ''))
      ) dic
  );

in
{
  options.xsession.xCompose = {
    enable = mkEnableOption "XCompose";
    combinations = mkOption {
      description = "Add compose key combinations";
      type = xComposeType;
      default = {};
      example = literalExample ''
        {
          Multi_key = {
            G = { A = "Α"; B = "Β";};
            g = { a = "α"; b = "β";};
          };
        }'';
    };

  };

  config = (
    mkIf (cfg.enable == true) {
      home.file.".XCompose".text = ''
        include "%L"
        ${builtins.concatStringsSep "\n" (lib.collect builtins.isString (xComposeGen cfg.combinations ""))}'';
    }
  );
}
