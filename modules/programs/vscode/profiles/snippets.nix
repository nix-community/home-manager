{
  cfg,
  lib,
  pkgs,
}@inputs:
rec {
  helpers = import ../path-helpers.nix inputs;

  inherit (cfg) mutableProfile;
  inherit (helpers) jsonSource hasAttrKey snippetsDirectory;

  globalSnippets =
    profile:
    lib.optionalAttrs (hasAttrKey "globalSnippets" profile) {
      "global.code-snippets" = profile.globalSnippets;
    };

  languageSnippets =
    profile:
    lib.optionalAttrs (hasAttrKey "languageSnippets" profile) (
      lib.mapAttrs' (
        language: snippet: lib.nameValuePair "${language}.json" snippet
      ) profile.languageSnippets
    );

  getProfileSnippets = profile: (globalSnippets profile) // (languageSnippets profile);

  # profiles are immutable by default and nix store origins enforce that.
  #
  # however, this allows to create mutable files by creating the immutable
  # store with a `.immutable-` prefix to the filename, and then the mutable file
  # is created during activation by the `onChange` hook for mutable profiles.
  #
  profileSnippetsFiles =
    profileName: profile:
    lib.mapAttrs' (
      snippetKey: snippet:
      let
        # if profile is mutable
        #   (hidden immutable nix store) .immutable-snippet.json -> (visible mutable copy) snippet.json
        #
        #   sourceFilename = "snippet.json"
        #   storeFilename = ".immutable-snippet.json"
        #
        # else
        #   (visible immutable nix store) snippet.json
        #
        #   sourceFilename = "snippet.json"
        #   storeFilename = "snippet.json"
        #
        snippetsDir = snippetsDirectory profileName;

        sourceFilename = snippetKey;
        storeFilename = "${lib.optionalString mutableProfile ".immutable-"}${sourceFilename}";
      in
      lib.nameValuePair "${snippetsDir}/${storeFilename}" {
        source = jsonSource "${profileName}-user-snippets-${snippetKey}" snippet;
        onChange = lib.mkIf mutableProfile ''
          echo "Regenerating file from source: ${storeFilename} -> ${sourceFilename}"

          run cp -vf "$HOME/${snippetsDir}/${storeFilename}" "$HOME/${snippetsDir}/${sourceFilename}"
        '';
      }
    ) (getProfileSnippets profile);

  profilesSnippetsFiles = [ ];
}
