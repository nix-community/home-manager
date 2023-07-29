# Used by the home-manager tool to present news to the user. The content of this
# file is considered internal and the exported fields may change without
# warning.

{ newsJsonFile, newsReadIdsFile ? null }:

let
  inherit (builtins)
    concatStringsSep filter hasAttr isString length optionalString readFile
    replaceStrings sort split;

  newsJson = builtins.fromJSON (builtins.readFile newsJsonFile);

  # Sorted and relevant entries.
  relevantEntries =
    sort (a: b: a.time > b.time) (filter (e: e.condition) newsJson.entries);

  newsReadIds = if newsReadIdsFile == null then
    { }
  else
    let ids = filter isString (split "\n" (readFile newsReadIdsFile));
    in builtins.listToAttrs (map (id: {
      name = id;
      value = null;
    }) ids);

  newsIsRead = entry: hasAttr entry.id newsReadIds;

  newsUnread = let pred = entry: entry.condition && !newsIsRead entry;
  in filter pred relevantEntries;

  prettyTime = t: replaceStrings [ "T" "+00:00" ] [ " " "" ] t;

  layoutNews = entries:
    let
      mkTextEntry = entry:
        let flag = if newsIsRead entry then "read" else "unread";
        in ''
          * ${prettyTime entry.time} [${flag}]

            ${replaceStrings [ "\n" ] [ "\n  " ] entry.message}
        '';
    in concatStringsSep "\n\n" (map mkTextEntry entries);
in {
  meta = {
    numUnread = length newsUnread;
    display = newsJson.display;
    ids = concatStringsSep "\n" (map (e: e.id) newsJson.entries);
  };
  news = {
    all = layoutNews relevantEntries;
    unread = layoutNews newsUnread;
  };
}
