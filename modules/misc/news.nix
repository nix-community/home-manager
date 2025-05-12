{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkOption types;

  cfg = config.news;

  entryModule = types.submodule (
    { config, ... }:
    {
      options = {
        id = mkOption {
          internal = true;
          type = types.str;
          description = ''
            A unique entry identifier. By default it is a base16
            formatted hash of the entry message.
          '';
        };

        time = mkOption {
          internal = true;
          type = types.str;
          example = "2017-07-10T21:55:04+00:00";
          description = ''
            News entry time stamp in ISO-8601 format. Must be in UTC
            (ending in '+00:00').
          '';
        };

        condition = mkOption {
          internal = true;
          default = true;
          description = "Whether the news entry should be active.";
        };

        message = mkOption {
          internal = true;
          type = types.str;
          description = "The news entry content.";
        };
      };

      config = {
        id = lib.mkDefault (builtins.hashString "sha256" config.message);
      };
    }
  );

  isNixFile = n: v: v == "regular" && lib.hasSuffix ".nix" n;
  isDirectory = n: v: v == "directory";

  # Recursively collect all .nix files from a directory
  collectNixFiles =
    dir:
    let
      contents = builtins.readDir dir;
      files = lib.filterAttrs isNixFile contents;
      fileList = map (file: dir + "/${file}") (builtins.attrNames files);

      # Process subdirectories
      subdirs = lib.filterAttrs isDirectory contents;
      subdirFiles = lib.concatMap (subdir: collectNixFiles (dir + "/${subdir}")) (
        builtins.attrNames subdirs
      );
    in
    fileList ++ subdirFiles;

  newsFiles = collectNixFiles ./news;
  newsEntries = builtins.map (
    newsFile:
    let
      imported = import newsFile;
    in
    if builtins.isFunction imported then imported { inherit config lib pkgs; } else imported
  ) newsFiles;
in
{
  meta.maintainers = [ lib.maintainers.rycee ];

  options = {
    news = {
      display = mkOption {
        type = types.enum [
          "silent"
          "notify"
          "show"
        ];
        default = "notify";
        description = ''
          How unread and relevant news should be presented when
          running {command}`home-manager build` and
          {command}`home-manager switch`.

          The options are

          `silent`
          : Do not print anything during build or switch. The
            {command}`home-manager news` command still
            works for viewing the entries.

          `notify`
          : The number of unread and relevant news entries will be
            printed to standard output. The {command}`home-manager
            news` command can later be used to view the entries.

          `show`
          : A pager showing unread news entries is opened.
        '';
      };

      entries = mkOption {
        internal = true;
        type = types.listOf entryModule;
        default = [ ];
        description = "News entries.";
      };

      json = {
        output = mkOption {
          internal = true;
          type = types.package;
          description = "The generated JSON file package.";
        };
      };
    };
  };

  config = {
    news.json.output = pkgs.writeText "hm-news.json" (
      builtins.toJSON { inherit (cfg) display entries; }
    );

    # News entries are now loaded from individual files in the news directory
    news.entries = newsEntries;
  };
}
