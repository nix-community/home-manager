{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.vdirsyncer;
  
  vdirsyncerAccounts =
    filterAttrs (_: v: v.vdirsyncer.enable) config.accounts.calendar.accounts;

  wrap = s: ''"${s}"'';

  listString = l: ''[${concatStringsSep ", " l}]'';
  
  boolString = b: if b then "true" else "false";

  localStorage = a:
  with a.vdirsyncer.local;
  filterAttrs (_: v: v != null)
  (getAttrs [ "type" "path" "fileExt" "encoding" "postHook"] a.vdirsyncer.local);

  remoteStorage = a:
  with a.vdirsyncer.remote;
  filterAttrs (_: v: v != null)
  (getAttrs [
    "type"
    "url"
    "itemTypes"
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
    "tokenFile"
    "clientId"
    "clientSecret"
    "timeRange"
   ] a.vdirsyncer.remote);

  pair = a:
  with a.vdirsyncer;
  filterAttrs (_: v: v != null && v != [])
  (getAttrs [ "collections" "conflictResolution" "metadata" "partialSync" ] a.vdirsyncer);

  pairs = mapAttrs (_: v: pair v) vdirsyncerAccounts;
  localStorages = mapAttrs (_: v: localStorage v) vdirsyncerAccounts;
  remoteStorages = mapAttrs (_: v: remoteStorage v) vdirsyncerAccounts;

  optionString = n: v:
  if (n == "type") then ''type = "${v}"''
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
    item_types = ${listString (map wrap v)}
  ''
  else if (n == "userName") then ''username = "${v}"''
  else if (n == "userNameCommand") then ''
    username.fetch = ${listString (map wrap (["command"] ++ v))}
  ''
  else if (n == "password") then ''password = "${v}"''
  else if (n == "passwordCommand") then ''
    password.fetch = ${listString (map wrap (["command"] ++ v))}
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
    auth_cert = ${listString (map wrap v)}
  ''
  else if (n == "userAgent") then ''useragent = "${v}"''
  else if (n == "tokenFile") then ''token_file = "${v}"''
  else if (n == "clientId") then ''client_id = "${v}"''
  else if (n == "clientSecret") then ''client_secret = "${v}"''
  else if (n == "metadata") then ''metadata = ${listString (map wrap v)}''
  else if (n == "partialSync") then ''partial_sync = "${v}"''
  else if (n == "collections") then
    let 
           contents = map (c: if (isString c) 
                          then ''"${c}"''
                          else mkList (map wrapString c)) cs;
    in ''collections = ${listString contents}''
  else if (n == "conflictResolution") then 
    if (isString v)
      then ''conflict_resolution = "${v}"''
      else ''conflict_resolution = ${mkList (map wrapString (["command"] ++ v))}''
  else throw "Unrecognized option: ${n}";

  attrsString = a: concatStringsSep "\n" (mapAttrsToList optionString a);

  pairString = n: v: ''
    [pair ${n}]
    a = "${n}_remote"
    b = "${n}_local"
    ${attrsString v}
  '';

  configFile = pkgs.writeText "config" ''
    [general]
    status_path = "${cfg.statusPath}"

    ### Pairs

    ${concatStringsSep "\n" (mapAttrsToList pairString pairs)}

    ### Local storages

    ${concatStringsSep "\n" (mapAttrsToList (n: v: "[storage ${n}_local]" + "\n" + attrsString v) localStorages)}

    ### Remote storages

    ${concatStringsSep "\n" (mapAttrsToList (n: v: "[storage ${n}_remote]" + "\n" + attrsString v) remoteStorages)}
  '';
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
    };
  };

  config = mkIf cfg.enable {
    assertions = let

      requiredOptions = t:
      if (t == "caldav" || t == "carddav" || t == "http") then [ "url" ]
      else if (t == "filesystem") then [ "path" "fileExt" ]
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
          assertion = length (filter (x: x) [
                                (hasAttr "password" v)
                                (hasAttr "passwordCommand" v)
                                (hasAttr "passwordPrompt" v)
                              ]) < 2;
          message = ''
            Only one of password, passwordCommand, passwordPrompt can be set
            for storage ${n}.
          '';
        }

        {
          assertion = !(hasAttr "userName" v && hasAttr "userNameCommand" v);
          message = ''
            Only one of userName, userNameCommand can be set
            for storage ${n}.
          '';
        }
      ] ++
      (let allowed = allowedOptions v.type ++ (requiredOptions v.type);
      in mapAttrsToList (
        a: v': [
          {
            assertion = (elem a allowed);
            message = ''
              Storage ${n} is of type ${v.type}. Option
              ${a} is not allowed for this type.
            '';
          }
        ] ++
        (let required = requiredOptions v.type;
         in map (a: [{
                assertion = hasAttr a v;
                message = ''
                  Storage ${n} is of type ${v.type}, but required
                  option ${a} is not set.
                '';
              }]) required)
      ) (removeAttrs v ["type" "_module"]));

      storageAssertions = flatten (mapAttrsToList assertStorage localStorages)
                          ++ flatten (mapAttrsToList assertStorage remoteStorages);


    in storageAssertions; 
    home.packages = [ cfg.package ];
    xdg.configFile."vdirsyncer/config.test".source = configFile;
  };
}
