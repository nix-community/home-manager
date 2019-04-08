{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.vdirsyncer;
  
  ## Type definitions
  collection = types.either types.str (types.listOf types.str);
  storageType = types.enum [
    "caldav" "carddav" "http"
    "filesystem" "singlefile"
    "google_calendar" "google_contacts"
  ];

  storage = types.submodule {
    options = {
      type = mkOption {
        type = storageType;
        description = "The type of the storage.";
      };

      ## Options for local storages

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

      ## Options for remote storages

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
    };
  };
  
  pair = types.submodule {
    options = {
      a = mkOption {
        type = types.str;
        description = ''
          One of the storages to synchronize.
        '';
      };

      b = mkOption {
        type = types.str;
        description = ''
          One of the storages to synchronize.
        '';
      };

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
    };
  };

  configFile = pkgs.writeText "config" (if cfg.config == null then "" else with cfg.config;
    let
      wrapString = s: ''"'' + s + ''"'';
      mkList = l: ''[${concatStringsSep ", " l}]'';

      collectionsString = cs: if (cs == null)
        then "null"
        else let 
               contents = map (c: if (isString c) 
                                  then ''"${c}"''
                                  else mkList (map wrapString c)) cs;
             in mkList contents; 

      conflictResolutionString = cr: optionalString (cr != null) (
        if (isString cr) then ''conflict_resolution = "${cr}"''
                         else ''conflict_resolution = ${mkList (map wrapString (["command"] ++ cr))}''
      );

      metadataString = md: optionalString (md != []) ''
        metadata = ${mkList (map wrapString md)}
      '';

      partialSyncString = ps: optionalString (ps != null) ''
        partial_sync = "${ps}"
      '';
      
      pairString = n: p: ''
        [pair ${n}]
        a = "${p.a}"
        b = "${p.b}"
        collections = ${collectionsString p.collections}
        ${conflictResolutionString p.conflictResolution}
        ${partialSyncString p.partialSync}
        ${metadataString p.metadata}
      '';

      optionString = n: v:
      if v == null then ""
      else if (n == "type") then ''type = "${v}"''
      else if (n == "path") then ''path = "${v}"''
      else if (n == "fileExt") then ''fileext = "${v}"''
      else if (n == "encoding") then ''encoding = "${v}"''
      else if (n == "postHook") then ''post_hook = "${v}"''
      else if (n == "url") then ''url = "${v}"''
      else if (n == "timeRange") then ''
        start_date = "${v.start}"
        end_date = "${v.end}"
      ''
      else if (n == "itemTypes") then ''
        item_types = ${mkList (map wrapString v)}
      ''
      else if (n == "userName") then ''username = "${v}"''
      else if (n == "userNameCommand") then ''
        username.fetch = ${mkList (map wrapString (["command"] ++ v))}
      ''
      else if (n == "password") then ''password = "${v}"''
      else if (n == "passwordCommand") then ''
        password.fetch = ${mkList (map wrapString (["command"] ++ v))}
      ''
      else if (n == "passwordPrompt") then ''
        password.fetch = ["prompt", "${v}"]
      ''
      else if (n == "verify") then ''
        verify = ${if v then "true" else "false"}
      ''
      else if (n == "verifyFingerprint") then ''
        verify_fingerprint = "${v}"
      ''
      else if (n == "auth") then ''auth = "${v}"''
      else if (n == "authCert" && isString(v)) then ''
        auth_cert = "${v}"
      ''
      else if (n == "authCert") then ''
        auth_cert = ${mkList (map wrapString v)}
      ''
      else if (n == "userAgent") then ''useragent = "${v}"''
      else if (n == "tokenFile") then ''token_file = "${v}"''
      else if (n == "clientId") then ''client_id = "${v}"''
      else if (n == "clientSecret") then ''client_secret = "${v}"''
      else throw "Unrecognized option: ${n}";

      storageString = n: s: ''
        [storage ${n}]
        type = "${s.type}"
        ${concatStringsSep "\n" (
          filter (x: x != "") (mapAttrsToList optionString (removeAttrs s ["type" "_module"])) 
        )}
      '';

    in ''
       [general]
       status_path = "${statusPath}"

       ${concatStringsSep "\n" (mapAttrsToList pairString pairs)}
       ${concatStringsSep "\n" (mapAttrsToList storageString storages)}
    '');
in

{
  options = {
    programs.vdirsyncer = {
      enable = mkEnableOption "vdirsyncer";

      package = mkOption {
        type = types.package;
        default = pkgs.vdirsyncer;
        defaultText = "pkgs.vdirsyncer";
        description = ''
          vdirsyncer package to use.
        '';
      };

      config = mkOption {
        default = null;
        description = ''
          Configuration for vdirsyncer.
        '';
        type = types.nullOr (types.submodule {
          options = {

            statusPath = mkOption {
              type = types.str;
              default = "$XDG_DATA_HOME/vdirsyncer/status";
              description = ''
                A directory where vdirsyncer will store some additional data for the next sync.
                </para>

                <para>For more information, see
                <link xlink:href="https://vdirsyncer.pimutils.org/en/stable/config.html#general-section"/>
              '';
            };

            pairs = mkOption {
              type = types.attrsOf pair;
              default = {};
              description = ''
                Pairs of storages to synchronize.
              '';
            };

            storages = mkOption {
              type = types.attrsOf storage;
              default = {};
              description = ''The storages to synchronize.'';
            };

          };
        });
      };    
    };
  };

  config = mkIf cfg.enable {
    assertions = let

      requiredOptions = t:
      if (t == "caldav" || t == "carddav" || t == "http") then [ "url" ]
      else if (t == "filesystem") then [ "path" "fileext" ]
      else if (t == "singlefile") then [ "path" ]
      else if (t == "google_calendar" || t == "google_contacts") then
        [ "tokenFile" "clientId" "clientSecret" ]
      else throw "Unrecognized storage type: ${t}";

      allowedOptions = let
        remoteOptions = [
          "userName"
          "userNameCommand"
          "password"
          "passwordCommand"
          "passwordPrompt"
          "verify"
          "verifyFingerprint"
          "auth"
          "authCert"
          "userAgent"
        ];
      in t:
      if (t == "caldav")
        then [ "timeRange" "itemTypes" ] ++ remoteOptions
      else if (t == "carddav" || t == "http")
        then remoteOptions
      else if (t == "filesystem")
        then [ "fileExt" "encoding" "postHook" ]
      else if (t == "singlefile")
        then [ "encoding" ]
      else if (t == "google_calendar") then
        [ "timeRange" "itemTypes"]
      else if (t == "google_contacts") then []
      else throw "Unrecognized storage type: ${t}";

      assertStorage = n: v:
      [
        {
          assertion = length (filter (x: x != null) [v.password v.passwordCommand v.passwordPrompt]) < 2;
          message = ''
            Only one of password, passwordCommand, passwordPrompt can be set
            for storage ${n}.
          '';
        }

        {
          assertion = v.userName == null || v.userNameCommand == null;
          message = ''
            Only one of userName, userNameCommand can be set
            for storage ${n}.
          '';
        }
      ] ++
      (let required = requiredOptions v.type;
          allowed = allowedOptions v.type;
      in mapAttrsToList (
        a: v': [
          {
            assertion = !(elem a required) || v' != null;
            message = ''
              Storage ${n} is of type ${v.type}, but required
              option ${a} is not set.
            '';
          }

          {
            assertion = v' == null || (elem a (required ++ allowed));
            message = ''
              Storage ${n} is of type ${v.type}. Option
              ${a} is not allowed for this type.
            '';
          }
        ]
      ) (removeAttrs v ["type" "_module"]));

      storageAssertions = flatten (mapAttrsToList assertStorage cfg.config.storages);

      assertPair = n: v: [
        {
          assertion = hasAttr v.a cfg.config.storages;
          message = ''
            Storage ${v.a} in pair ${n} not found
            in the set of storages.
          '';
        }
        
        {
          assertion = hasAttr v.b cfg.config.storages;
          message = ''
            Storage ${v.b} in pair ${n} not found
            in the set of storages.
          '';
        }
      ];

      pairAssertions = flatten (mapAttrsToList assertPair cfg.config.pairs);

    in storageAssertions ++ pairAssertions; 

    home.packages = [ cfg.package ];
    xdg.configFile."vdirsyncer/config.test".source = configFile;
  };
}
