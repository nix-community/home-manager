{ config, lib, pkgs, ... }:

with lib;

let

  vars = config.pam.sessionVariables;

in

{
  meta.maintainers = [ maintainers.rycee ];

  options = {
    pam.sessionVariables = mkOption {
      default = {};
      type = types.attrs;
      example = { EDITOR = "vim"; };
      description = ''
        Environment variables that will be set for the PAM session.
        The variable values must be as described in
        <citerefentry>
          <refentrytitle>pam_env.conf</refentrytitle>
          <manvolnum>5</manvolnum>
        </citerefentry>.
      '';
    };
  };

  config = mkIf (vars != {}) {
    home.file.".pam_environment".text =
      concatStringsSep "\n" (
        mapAttrsToList (n: v: "${n} OVERRIDE=\"${toString v}\"") vars
      ) + "\n";
  };
}
