{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (pkgs.stdenv) isDarwin;

  cfg = config.mozilla;

  defaultPaths = [
    # Link a .keep file to keep the directory around
    (pkgs.writeTextDir "lib/mozilla/native-messaging-hosts/.keep" "")
  ];

  thunderbirdNativeMessagingHostsPath =
    if isDarwin then "Library/Mozilla/NativeMessagingHosts" else ".mozilla/native-messaging-hosts";

  firefoxNativeMessagingHostsPath =
    if isDarwin then
      "Library/Application Support/Mozilla/NativeMessagingHosts"
    else
      ".mozilla/native-messaging-hosts";

  librewolfNativeMessagingHostsPath =
    if isDarwin then
      "Library/Application Support/LibreWolf/NativeMessagingHosts"
    else
      ".librewolf/native-messaging-hosts";
in
{
  meta.maintainers = with lib.maintainers; [
    booxter
    rycee
    lib.hm.maintainers.bricked
  ];

  options.mozilla = {
    firefoxNativeMessagingHosts = lib.mkOption {
      internal = true;
      type = with lib.types; listOf package;
      default = [ ];
      description = ''
        List of Firefox native messaging hosts to configure.
      '';
    };

    thunderbirdNativeMessagingHosts = lib.mkOption {
      internal = true;
      type = with lib.types; listOf package;
      default = [ ];
      description = ''
        List of Thunderbird native messaging hosts to configure.
      '';
    };

    librewolfNativeMessagingHosts = lib.mkOption {
      internal = true;
      type = with lib.types; listOf package;
      default = [ ];
      description = ''
        List of Librewolf native messaging hosts to configure.
      '';
    };
  };

  config =
    lib.mkIf
      (
        cfg.firefoxNativeMessagingHosts != [ ]
        || cfg.thunderbirdNativeMessagingHosts != [ ]
        || cfg.librewolfNativeMessagingHosts != [ ]
      )
      {
        home.file =
          let
            mkNmhLink =
              { name, nativeMessagingHosts }:
              let
                packageJoin = pkgs.symlinkJoin {
                  inherit name;
                  paths = lib.flatten (
                    lib.concatLists [
                      defaultPaths
                      nativeMessagingHosts
                    ]
                  );
                };
              in
              lib.mkIf (nativeMessagingHosts != [ ]) {
                source = "${packageJoin}/lib/mozilla/native-messaging-hosts";
                recursive = true;
                ignorelinks = true;
              };
          in
          if isDarwin then
            {
              "${thunderbirdNativeMessagingHostsPath}" = mkNmhLink {
                name = "th-native-messaging-hosts";
                nativeMessagingHosts = cfg.thunderbirdNativeMessagingHosts;
              };

              "${firefoxNativeMessagingHostsPath}" = mkNmhLink {
                name = "ff-native-messaging-hosts";
                nativeMessagingHosts = cfg.firefoxNativeMessagingHosts;
              };

              "${librewolfNativeMessagingHostsPath}" = mkNmhLink {
                name = "lw-native-messaging-hosts";
                nativeMessagingHosts = cfg.librewolfNativeMessagingHosts;
              };
            }
          else
            {
              "${firefoxNativeMessagingHostsPath}" = mkNmhLink {
                name = "mozilla-native-messaging-hosts";
                # on Linux, the directory is shared between Firefox and Thunderbird; merge both into one
                nativeMessagingHosts = [
                  cfg.firefoxNativeMessagingHosts
                  cfg.thunderbirdNativeMessagingHosts
                ];
              };

              "${librewolfNativeMessagingHostsPath}" = mkNmhLink {
                name = "librewolf-native-messaging-hosts";
                nativeMessagingHosts = cfg.librewolfNativeMessagingHosts;
              };
            };
      };
}
