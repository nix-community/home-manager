{ config, lib, ... }:

with lib;

{
  options.msmtp = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable msmtp.

        If enabled then it is possible to use the
        `--account` command line
        option to send a message for a given account using the
        {command}`msmtp` or {command}`msmtpq` tool.
        For example, {command}`msmtp --account=private` would
        send using the account defined in
        {option}`accounts.email.accounts.private`. If the
        `--account` option is not
        given then the primary account will be used.
      '';
    };

    tls.fingerprint = mkOption {
      type =
        types.nullOr (types.strMatching "([[:alnum:]]{2}:)+[[:alnum:]]{2}");
      default = null;
      example = "my:SH:a2:56:ha:sh";
      description = ''
        Fingerprint of a trusted TLS certificate.
        The fingerprint can be obtained by executing
        {command}`msmtp --serverinfo --tls --tls-certcheck=off`.
      '';
    };

    extraConfig = mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = { auth = "login"; };
      description = ''
        Extra configuration options to add to {file}`~/.msmtprc`.
        See <https://marlam.de/msmtp/msmtprc.txt> for
        examples.
      '';
    };
  };
}
