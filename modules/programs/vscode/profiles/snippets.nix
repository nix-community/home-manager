{
  cfg,
  lib,
  pkgs,
}@inputs:
rec {
  helpers = import ../path-helpers.nix inputs;

  inherit (helpers)
    getAttrKey
    globalSnippetKey
    hasValue
    mkConfigFile
    snippetsDirectory
    ;

  buildProfileSnippets =
    profileName: profile:
    let
      storeKey = "profile-${profileName}-snippets";
      storeDirectory = snippetsDirectory profileName;

      globalSnippets = (getAttrKey "globalSnippets" profile);
      languageSnippets = (getAttrKey "languageSnippets" profile);

      profileSnippets = lib.filterAttrs (key: snippet: (hasValue snippet)) (
        { }
        // (lib.optionalAttrs (hasValue globalSnippets) { "${globalSnippetKey}" = globalSnippets; })
        // (lib.optionalAttrs (hasValue languageSnippets) languageSnippets)
      );
    in
    {
      files = lib.mapAttrs' (
        sourceFilename: content:
        mkConfigFile {
          inherit
            storeKey
            storeDirectory
            sourceFilename
            content
            ;
        }
      ) profileSnippets;
    };

  snippetFiles = lib.map (snippets: snippets.files) (
    lib.mapAttrsToList buildProfileSnippets cfg.profiles
  );
}
