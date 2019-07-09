{ lib, ... }:

with lib;

let

  collection = types.either types.str (types.listOf types.str);

in

{
  options.vdirsyncer = {
    enable = mkEnableOption "synchronization using vdirsyncer";

    collections = mkOption {
      type = types.nullOr (types.listOf collection);
      default = null;
      description = ''
        The collections to synchronize between the storages.
      '';
    };

    conflictResolution = mkOption {
      type =
        types.nullOr
        (types.either
          (types.enum ["remote wins" "local wins"])
          (types.listOf types.str));
      default = null;
      description = ''
        What to do in case of a conflict between the storages. Either
        <literal>remote wins</literal> or
        <literal>local wins</literal> or
        a list that contains a command to run. By default, an error
        message is printed.
      '';
    };

    partialSync = mkOption {
      type = types.nullOr (types.enum [ "revert" "error" "ignore" ]);
      default = null;
      description = ''
        What should happen if synchronization in one direction
        is impossible due to one storage being read-only.
        Defaults to <literal>revert</literal>.
        </para><para>
        See
        <link xlink:href="https://vdirsyncer.pimutils.org/en/stable/config.html#pair-section"/>
        for more information.
      '';
    };

    metadata = mkOption {
      type = types.listOf types.str;
      default = [];
      example = [ "color" "displayname" ];
      description = ''
        Metadata keys that should be synchronized when vdirsyncer
        metasync is executed.
      '';
    };

    timeRange = mkOption {
      type = types.nullOr (types.submodule {
        options = {
          start = mkOption {
            type = types.str;
            description = "Start of time range to show.";
          };

          end = mkOption {
            type = types.str;
            description = "End of time range to show.";
          };
        };
      });
      default = null;
      description = ''
        A time range to synchronize. start and end can be any Python
        expression that returns a <literal>datetime.datetime</literal>
        object.
      '';
      example = {
        start = "datetime.now() - timedelta(days=365)";
        end = "datetime.now() + timedelta(days=365)";
      };
    };

    itemTypes = mkOption {
      type = types.nullOr (types.listOf types.str);
      default = null;
      description = ''
        Kinds of items to show. The default is to show everything.
        This depends on particular features of the server, the results
        are not validated.
      '';
    };

    verify = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = "Verify SSL certificate.";
    };

    verifyFingerprint = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Optional. SHA1 or MD5 fingerprint of the expected server certificate.
        </para><para>
        See
        <link xlink:href="https://vdirsyncer.pimutils.org/en/stable/ssl-tutorial.html#ssl-tutorial"/>
        for more information.
      '';
    };

    auth = mkOption {
      type = types.nullOr (types.enum ["basic" "digest" "guess"]);
      default = null;
      description = ''
        Authentication settings. The default is <literal>basic</literal>.
      '';
    };

    authCert = mkOption {
      type = types.nullOr (types.either types.str (types.listOf types.str));
      default = null;
      description = ''
        Either a path to a certificate with a client certificate and
        the key or a list of paths to the files with them.
     '';
    };

    userAgent = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        The user agent to report to the server. Defaults to
        <literal>vdirsyncer</literal>.
      '';
    };

    postHook = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Command to call for each item creation and modification.
        The command will be called with the path of the new/updated
        file.
      '';
    };

    ## Options for google storages

    tokenFile = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        A file path where access tokens are stored.
      '';
    };

    clientIdCommand = mkOption {
      type = types.nullOr (types.listOf types.str);
      default = null;
      example = [ "pass" "client_id" ];
      description = ''
        A command that prints the OAuth credentials to standard
        output.
        </para><para>
        See
        <link xlink:href="https://vdirsyncer.pimutils.org/en/stable/config.html#google"/>
        for more information.
      '';
    };

    clientSecretCommand = mkOption {
      type = types.nullOr (types.listOf types.str);
      default = null;
      example = [ "pass" "client_secret" ];
      description = ''
        A command that prints the OAuth credentials to standard
        output.
        </para><para>
        See
        <link xlink:href="https://vdirsyncer.pimutils.org/en/stable/config.html#google"/>
        for more information.
      '';
    };
  };
}
