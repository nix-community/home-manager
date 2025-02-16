{ config, lib, pkgs, ... }:

with lib;

let
  inherit (pkgs.stdenv) isDarwin;

  cfg = config.mozilla;

  defaultPaths = [
    # Link a .keep file to keep the directory around
    (pkgs.writeTextDir "lib/mozilla/native-messaging-hosts/.keep" "")
  ];

  thunderbirdNativeMessagingHostsPath = if isDarwin then
    "Library/Mozilla/NativeMessagingHosts"
  else
    ".mozilla/native-messaging-hosts";

  firefoxNativeMessagingHostsPath = if isDarwin then
    "Library/Application Support/Mozilla/NativeMessagingHosts"
  else
    ".mozilla/native-messaging-hosts";
in {
  meta.maintainers =
    [ maintainers.booxter maintainers.rycee hm.maintainers.bricked ];

  options.mozilla = {
    firefoxNativeMessagingHosts = mkOption {
      internal = true;
      type = with types; listOf package;
      default = [ ];
      description = ''
        List of Firefox native messaging hosts to configure.
      '';
    };

    thunderbirdNativeMessagingHosts = mkOption {
      internal = true;
      type = with types; listOf package;
      default = [ ];
      description = ''
        List of Thunderbird native messaging hosts to configure.
      '';
    };
  };

  config = mkIf (cfg.firefoxNativeMessagingHosts != [ ]
    || cfg.thunderbirdNativeMessagingHosts != [ ]) {
      home.file = if isDarwin then
        let
          firefoxNativeMessagingHostsJoined = pkgs.symlinkJoin {
            name = "ff-native-messaging-hosts";
            paths = defaultPaths ++ cfg.firefoxNativeMessagingHosts;
          };
          thunderbirdNativeMessagingHostsJoined = pkgs.symlinkJoin {
            name = "th-native-messaging-hosts";
            paths = defaultPaths ++ cfg.thunderbirdNativeMessagingHosts;
          };
        in {
          "${thunderbirdNativeMessagingHostsPath}" = {
            source =
              "${thunderbirdNativeMessagingHostsJoined}/lib/mozilla/native-messaging-hosts";
            recursive = true;
          };

          "${firefoxNativeMessagingHostsPath}" = {
            source =
              "${firefoxNativeMessagingHostsJoined}/lib/mozilla/native-messaging-hosts";
            recursive = true;
          };
        }
      else
        let
          nativeMessagingHostsJoined = pkgs.symlinkJoin {
            name = "mozilla-native-messaging-hosts";
            # on Linux, the directory is shared between Firefox and Thunderbird; merge both into one
            paths = defaultPaths ++ cfg.firefoxNativeMessagingHosts
              ++ cfg.thunderbirdNativeMessagingHosts;
          };
        in {
          "${firefoxNativeMessagingHostsPath}" = {
            source =
              "${nativeMessagingHostsJoined}/lib/mozilla/native-messaging-hosts";
            recursive = true;
          };
        };
    };
}
