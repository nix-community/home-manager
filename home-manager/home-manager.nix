{ pkgs ? import <nixpkgs> {}
, confPath
, confAttr
, check ? true
, newsReadIdsFile ? null
}:

with pkgs.lib;

let

  env = import <home-manager> {
    configuration =
      let
        conf = import confPath;
      in
        if confAttr == "" then conf else conf.${confAttr};
    pkgs = pkgs;
    check = check;
  };

  newsReadIds =
    if newsReadIdsFile == null
    then []
    else splitString "\n" (fileContents newsReadIdsFile);

  newsIsRead = entry: builtins.elem entry.id newsReadIds;

  newsFiltered =
    let
      pred = entry: entry.condition && ! newsIsRead entry;
    in
      filter pred env.newsEntries;

  newsNumUnread = length newsFiltered;

  newsFileUnread = pkgs.writeText "news-unread.txt" (
    concatMapStringsSep "\n\n" (entry:
      let
        time = replaceStrings ["T"] [" "] (removeSuffix "+00:00" entry.time);
      in
        ''
          * ${time}

            ${replaceStrings ["\n"] ["\n  "] entry.message}
        ''
    ) newsFiltered
  );

  newsFileAll = pkgs.writeText "news-all.txt" (
    concatMapStringsSep "\n\n" (entry:
      let
        flag = if newsIsRead entry then "read" else "unread";
        time = replaceStrings ["T"] [" "] (removeSuffix "+00:00" entry.time);
      in
        ''
          * ${time} [${flag}]

            ${replaceStrings ["\n"] ["\n  "] entry.message}
        ''
    ) env.newsEntries
  );

  # File where each line corresponds to an unread news entry
  # identifier. If non-empty then the file ends in "\n".
  newsUnreadIdsFile = pkgs.writeText "news-unread-ids" (
    let
      text = concatMapStringsSep "\n" (entry: entry.id) newsFiltered;
    in
      text + optionalString (text != "") "\n"
  );

  newsInfo = pkgs.writeText "news-info.sh" ''
    local newsNumUnread=${toString newsNumUnread}
    local newsDisplay="${env.newsDisplay}"
    local newsFileAll="${newsFileAll}"
    local newsFileUnread="${newsFileUnread}"
    local newsUnreadIdsFile="${newsUnreadIdsFile}"
  '';

in
  {
    inherit (env) activationPackage;
    inherit newsInfo;
  }
