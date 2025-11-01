{
  cfg,
  lib,
  pkgs,
}@inputs:
rec {
  inherit (import ../path-helpers.nix inputs)
    getAttrKey
    globalSnippetKey
    hasValue
    mkConfigFile
    snippetsDirectory
    ;

  buildProfileSnippets =
    profileName: profile:
    let
      snippets = (getAttrKey "snippets" profile);
      globalSnippets = if (hasValue snippets) then (getAttrKey "global" snippets) else { };
      languageSnippets = if (hasValue snippets) then (getAttrKey "languages" snippets) else { };

      profileSnippets = lib.filterAttrs (key: snippet: (hasValue snippet)) (
        { }
        // (lib.optionalAttrs (hasValue globalSnippets) { "${globalSnippetKey}" = globalSnippets; })
        // (lib.optionalAttrs (hasValue languageSnippets) languageSnippets)
      );

      storeDirectory = snippetsDirectory profileName;
      storeKey = "profile-${profileName}-snippets";
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
