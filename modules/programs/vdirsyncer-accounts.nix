{ lib, ... }:

with lib;

let

  collection = types.either types.str (types.listOf types.str);

  remoteModule = types.submodule {
    options = {
      type = mkOption {
        type = types.enum [ "caldav" "http" "google_calendar" "google_contacts" ];
        description = "The type of the storage.";
      };

      url = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "The url of the storage.";
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
          A time range to synchronize. start and end
          can be any Python expression that returns
          a <literal>datetime.datetime</literal> object.
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
          Kinds of items to show. The default is to
          show everything. This depends on particular
          features of the server, the results are not
          validated.
        '';
      };

      userName = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "User name for authentication.";
      };

      userNameCommand = mkOption {
        type = types.nullOr (types.listOf types.str);
        default = null;
        example = [ "~/get-username.sh" ];
        description = ''
          A command that prints the user name to standard
          output.
        '';
      };
      password = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Password for authentication.";
      };

      passwordCommand = mkOption {
        type = types.nullOr (types.listOf types.str);
        default = null;
        example = [ "pass" "caldav" ];
        description = ''
          A command that prints the password to standard
          output.
        '';
      };

      passwordPrompt = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "Password for CalDAV";
        description = ''
          Show a prompt for the password with the specified
          text.
        '';
      };

      verify = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Verify SSL certificate. Defaults to <literal>true</literal>.";
      };

      verifyFingerprint = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Optional. SHA1 or MD5 fingerprint of the expected server certificate.</para>

          <para>See
          <link xlink:href="https://vdirsyncer.pimutils.org/en/stable/ssl-tutorial.html#ssl-tutorial"/>
          for more information.
        '';
      };

      auth = mkOption {
        type = types.nullOr (types.enum ["basic" "digest" "guess"]);
        default = null;
        description = ''
          Authentication settings. The default is <literal>"basic"</literal>.
        '';
      };

      authCert = mkOption {
        type = types.nullOr (types.either types.str (types.listOf types.str));
        default = null;
        description = ''
        Either a path to a certificate with a client certificate
        and the key or a list of paths to the files with them.
       '';
      };

      userAgent = mkOption {
        type = types.nullOr types.str;
        default = null;  
        description = ''
          The user agent to report to the server.
          Defaults to <literal>"vdirsyncer"</literal>.
        '';
      };

      ## Options for google storages

      tokenFile = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          A file path where access tokens
          are stored.
        '';
      };

      clientId = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          OAuth credentials, obtained from the Google API Manager.</para>

          <para> See
          <link xlink:href="https://vdirsyncer.pimutils.org/en/stable/config.html#google"/>
          for more information.
        '';
      };

      clientIdCommand = mkOption {
        type = types.nullOr (types.listOf types.str);
        default = null;
        example = [ "pass" "client_id" ];
        description = ''
          A command that prints the OAuth credentials to standard
          output.
          
          OAuth credentials, obtained from the Google API Manager.</para>

          <para> See
          <link xlink:href="https://vdirsyncer.pimutils.org/en/stable/config.html#google"/>
          for more information.
        '';
      };

      clientSecret = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          OAuth credentials, obtained from the Google API Manager.</para>

          <para> See
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
          
          OAuth credentials, obtained from the Google API Manager.</para>

          <para> See
          <link xlink:href="https://vdirsyncer.pimutils.org/en/stable/config.html#google"/>
          for more information.
        '';
      };
    };
  };

  localModule = types.submodule {
    options = {
      type = mkOption {
        type = types.enum [ "filesystem" "singlefile" ];
        description = "The type of the storage.";
      };

      path = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "The path of the storage.";
      };

      fileExt = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "The file extension to use.";
      };

      encoding = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          File encoding for items, both content and file name.
          Defaults to UTF-8.
        '';
      };

      postHook = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Command to call for each item creation and modification.
          The command will be called with the path of the new/updated
          file.
        '';
      };
    };
  };

in

{
  options.vdirsyncer = {
    enable = mkEnableOption "synchronization using vdirsyncer";

    collections = mkOption {
      type = types.nullOr (types.listOf collection);
      description = ''
        The collections to synchronize between the storages.
      '';
    };

    conflictResolution = mkOption {
      type = types.nullOr (types.either (types.enum ["a wins" "b wins"]) (types.listOf types.str));
      default = null;
      description = ''
        What to do in case of a conflict between the storages.
        Either <literal>"a wins"</literal>
        or <literal>"b wins"</literal>
        or a list that contains a command to run.
        By default, an error message is printed.
      '';
    };

    partialSync = mkOption {
      type = types.nullOr (types.enum [ "revert" "error" "ignore" ]);
      default = null;
      description = ''
        What should happen if synchronization in one direction
        is impossible due to one storage being read-only.
        Defaults to <literal>"revert"</literal>.</para>
        <para>See
        <link xlink:href="https://vdirsyncer.pimutils.org/en/stable/config.html#pair-section"/>
        for more information.
      '';
    };

    metadata = mkOption {
      type = types.listOf types.str;
      default = [];
      example = [ "color" "displayname" ];
      description = ''
        Metadata keys that should be synchronized
        when vdirsyncer metasync is executed.
      '';
    };

    local = mkOption {
      type = localModule;
      description = ''
        Settings for the calendar's local storage.
      '';
    };

    remote = mkOption {
      type = remoteModule;
      description = ''
        Settings for the calendar's remote storage.
      '';
    };
  };
}
