{ config, lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  options.mblaze = {
    enable = lib.mkEnableOption "mblaze for this email account";

    sendMailCommand = mkOption {
      type = with types; nullOr str;
      default = null;
      example = "msmtpq --read-envelope-from --read-recipients";
      description = ''
        Command to send a mail, written to the `Sendmail:` entry of the
        account profile. If msmtp is enabled for the account, then this
        is set to
        {command}`msmtpq --read-envelope-from --read-recipients`.

        {manpage}`mcom(1)` appends the `Sendmail-Args:` entry to it,
        `-t` by default, which asks for the recipients to be collected
        from the message headers. Set that entry through
        [](#opt-accounts.email.accounts._name_.mblaze.settings) for a
        command that takes its arguments differently.

        When left null the entry is omitted and mblaze falls back to
        `sendmail` from {env}`PATH`.
      '';
    };

    settings = mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = {
        Scan-Format = "%c%u%r %-3n %10d %17f %t %2i%s";
      };
      description = ''
        Entries added to this mblaze account profile, as documented in
        {manpage}`mblaze-profile(5)`. An entry defined here overrides
        the generated one of the same name, as well as the one defined
        by [](#opt-programs.mblaze.settings).
      '';
    };
  };

  config = {
    mblaze.sendMailCommand = lib.mkIf config.msmtp.enable (
      lib.mkDefault "msmtpq --read-envelope-from --read-recipients"
    );
  };
}
