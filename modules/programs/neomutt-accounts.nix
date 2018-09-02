{ config, lib, ... }:

with lib;

{
  options.neomutt = {
    enable = mkOption {
      type = types.enum [ "none" "maildir" "imap" ];
      default = "none";
      description = ''
        Whether to enable this account in NeoMutt and which
        account protocol to use.
      '';
    };

    imap.idle = mkOption {
      type = types.bool;
      default = false;
      description = ''
        If set, NeoMutt will attempt to use the IDLE extension.
      '';
    };

    mailboxes = mkOption {
      type = types.listOf types.str;
      default = [];
      example = ["github" "Lists/nix" "Lists/haskell-cafe"];
      description = ''
        A list of mailboxes.
      '';
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      example = "color status cyan default";
      description = ''
        Extra lines to add to the folder hook for this account.
      '';
    };
  };
}
