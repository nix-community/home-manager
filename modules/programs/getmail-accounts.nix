{ config, lib, ... }:

with lib;

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
      example = [ "INBOX" "INBOX.spam" ];
      description = ''
        A non-empty list of mailboxes. To download all mail you can
        use the <literal>ALL</literal> mailbox.
      '';
    };

    delete = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enable if you want to delete read messages from the server. Most
        users should either enable <literal>delete</literal> or disable
        <literal>readAll</literal>.
      '';
    };

    readAll = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Enable if you want to fetch all, even the read messages from the
        server. Most users should either enable <literal>delete</literal> or
        disable <literal>readAll</literal>.
      '';
    };

  };
}
