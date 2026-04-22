{ lib, ... }:
let
  inherit (lib) mkOption mkEnableOption types;
in
{
  options.getmail = {
    enable = mkEnableOption "the getmail mail retriever for this account";

    destinationCommand = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "\${pkgs.maildrop}/bin/maildrop";
      description = ''
        Specify a command delivering the incoming mail to your maildir.
      '';
    };

    mailboxes = mkOption {
      type = types.nonEmptyListOf types.str;
      default = [ ];
      example = [
        "INBOX"
        "INBOX.spam"
      ];
      description = ''
        A non-empty list of mailboxes. To download all mail you can
        use the `ALL` mailbox.
      '';
    };

    delete = mkEnableOption "deleting read messages from the server. Most users should either enable `delete` or disable `readAll`";

    readAll =
      mkEnableOption "fetching all messages including read ones. Most users should either enable `delete` or disable `readAll`"
      // {
        default = true;
      };

  };
}
