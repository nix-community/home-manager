{ lib, ... }:

with lib;

rec {
  settingsType = with types;
    coercedTo (addCheck (attrsOf nodeType) (attrs: !(attrs ? settings)))
    attrValues (listOf nodeType);

  bookmarkSubmodule = types.submodule ({ name, ... }: {
    options = {
      name = mkOption {
        type = types.str;
        default = name;
        description = "Bookmark name.";
      };

      tags = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Bookmark tags.";
      };

      keyword = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Bookmark search keyword.";
      };

      url = mkOption {
        type = types.str;
        description = "Bookmark url, use %s for search terms.";
      };
    };
  }) // {
    description = "bookmark submodule";
  };

  bookmarkType = types.addCheck bookmarkSubmodule (x: x ? "url");

  directoryType = types.submodule ({ name, ... }: {
    options = {
      name = mkOption {
        type = types.str;
        default = name;
        description = "Directory name.";
      };

      bookmarks = mkOption {
        type = types.listOf nodeType;
        default = [ ];
        description = "Bookmarks within directory.";
      };

      toolbar = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Make this the toolbar directory. Note, this does _not_
          mean that this directory will be added to the toolbar,
          this directory _is_ the toolbar.
        '';
      };
    };
  }) // {
    description = "directory submodule";
  };

  nodeType = types.either bookmarkType directoryType;
}
