{ config, lib, ... }:

with lib;

{
  options.msmtp = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable msmtp.
        </para><para>
        If enabled then it is possible to use the
        <parameter class="command">--account</parameter> command line
        option to send a message for a given account using the
        <command>msmtp</command> or <command>msmtpq</command> tool.
        For example, <command>msmtp --account=private</command> would
        send using the account defined in
        <option>accounts.email.accounts.private</option>. If the
        <parameter class="command">--account</parameter> option is not
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
        <command>msmtp --serverinfo --tls --tls-certcheck=off</command>.
      '';
    };

    extraConfig = mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = { auth = "login"; };
      description = ''
        Extra configuration options to add to <filename>~/.msmtprc</filename>.
        See <link xlink:href="https://marlam.de/msmtp/msmtprc.txt"/> for
        examples.
      '';
    };
  };
}
