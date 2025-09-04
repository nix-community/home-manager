{ lib, config, ... }:

let
  inherit (lib) types mkOption;
  dynamicType = types.nullOr (types.either types.str (types.listOf types.str));
in
{
  options.pimsync = {
    enable = lib.mkEnableOption "synchronization using pimsync";

    url = mkOption {
      type = dynamicType;
      default = null;
      example = [
        "cmd"
        "secret-store"
        "--get-caldav-url"
      ];
      description = ""; # TODO: Description
    };

    userName = mkOption {
      type = dynamicType;
      default = null;
      example = [
        "cmd"
        "secret-store"
        "--get-caldav-username"
      ];
      description = ""; # TODO: Description
    };

    password = mkOption {
      type = dynamicType;
      default = null;
      example = [
        "shell"
        "pass"
        "dav"
        "|"
        "head"
        "-1"
      ];
      description = ""; # TODO: Description
    };

    collection = mkOption {
      type = types.oneOf [
        (types.enum [
          "all"
          "fromLocal"
          "fromRemote"
        ])
        (types.listOf (types.either types.str (types.attrsOf types.str)))
      ];
      default = "all";
      example = [
        "work"
        "school"
      ];
      description = ""; # TODO: Description
    };

    conflictResolution = mkOption {
      type = types.nullOr (
        types.oneOf [
          (types.enum [
            "keepLocal"
            "keepRemote"
          ])
          (types.listOf types.str)
        ]
      );
      default = null;
      example = [
        "cmd"
        "nvim"
        "-d"
      ];
      description = ""; # TODO: Description
    };

    onEmpty = mkOption {
      type = types.nullOr (
        types.enum [
          "skip"
          "sync"
        ]
      );
      default = null;
      description = ""; # TODO: Description
    };

    onDelete = mkOption {
      type = types.nullOr (
        types.enum [
          "skip"
          "sync"
        ]
      );
      default = null;
      description = ""; # TODO: Description
    };

    userAgent = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ""; # TODO: Description
    };

    collectionId = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ""; # TODO: Description
    };

    localReadOnly = mkOption {
      type = types.bool;
      default = false;
      description = ""; # TODO: Description
    };

    remoteReadOnly = mkOption {
      type = types.bool;
      default = false;
      description = ""; # TODO: Description
    };

    interval = mkOption {
      type = types.nullOr types.ints.positive;
      default = null;
      description = ""; # TODO: describe
    };
  };
}
