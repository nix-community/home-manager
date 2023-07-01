{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.pam;

in {
  meta.maintainers = with maintainers; [ rycee veehaitch ];

  options = {
    pam.sessionVariables = mkOption {
      default = { };
      type = types.attrs;
      example = { EDITOR = "vim"; };
      description = ''
        Environment variables that will be set for the PAM session.
        The variable values must be as described in
        {manpage}`pam_env.conf(5)`.

        Note, this option will become deprecated in the future and its use is
        therefore discouraged.
      '';
    };

    pam.yubico.authorizedYubiKeys = {
      ids = mkOption {
        type = with types;
          let
            yubiKeyId = addCheck str (s: stringLength s == 12) // {
              name = "yubiKeyId";
              description = "string of length 12";
            };
          in listOf yubiKeyId;
        default = [ ];
        description = ''
          List of authorized YubiKey token IDs. Refer to
          <https://developers.yubico.com/yubico-pam>
          for details on how to obtain the token ID of a YubiKey.
        '';
      };

      path = mkOption {
        type = types.str;
        default = ".yubico/authorized_yubikeys";
        description = ''
          File path to write the authorized YubiKeys,
          relative to {env}`HOME`.
        '';
      };
    };
  };

  config = mkMerge [
    (mkIf (cfg.sessionVariables != { }) {
      home.file.".pam_environment".text = concatStringsSep "\n"
        (mapAttrsToList (n: v: ''${n} OVERRIDE="${toString v}"'')
          cfg.sessionVariables) + "\n";
    })

    (mkIf (cfg.yubico.authorizedYubiKeys.ids != [ ]) {
      home.file.${cfg.yubico.authorizedYubiKeys.path}.text =
        concatStringsSep ":"
        ([ config.home.username ] ++ cfg.yubico.authorizedYubiKeys.ids);
    })
  ];
}
