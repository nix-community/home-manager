{
  package,
  packageName ? package.pname,
  ...
}@forkInputs:
{
  config,
  lib,
  pkgs,
  ...
}@inputs:
let
  helpers = import ../test-helpers.nix (forkInputs // inputs);

  inherit (helpers)
    elixirSnippetsJsonPath
    elixirSnippetsObject
    globalSnippetsJsonPath
    globalSnippetsObject
    haskellSnippetsJsonPath
    haskellSnippetsObject
    userDirectory
    ;

  forkConfig = {
    inherit package packageName;

    enable = true;

    # when multiple profiles are defined, the profiles are immutable by default.
    #
    profiles = {
      default = {
        globalSnippets = globalSnippetsObject;

        languageSnippets = {
          elixir = elixirSnippetsJsonPath;
          haskell = haskellSnippetsJsonPath;
        };
      };

      work = {
        globalSnippets = globalSnippetsJsonPath;

        languageSnippets = {
          elixir = elixirSnippetsObject;
          haskell = haskellSnippetsObject;
        };
      };
    };
  };
in
{
  config = lib.setAttrByPath [ "programs" package.pname ] forkConfig // {
    nmt.script = ''
      echo "pname: ${package.pname}, packageName: ${packageName}"
      echo "userDirectory: ${userDirectory}"

      # default profile: global snippets
      #
      assertFileExists "home-files/${userDirectory}/snippets/global.code-snippets"
      assertFileContent "home-files/${userDirectory}/snippets/global.code-snippets" "${globalSnippetsJsonPath}"

      # default profile: elixir snippets
      #
      assertFileExists "home-files/${userDirectory}/snippets/elixir.json"
      assertFileContent "home-files/${userDirectory}/snippets/elixir.json" "${elixirSnippetsJsonPath}"

      # default profile: haskell snippets
      #
      assertFileExists "home-files/${userDirectory}/snippets/haskell.json"
      assertFileContent "home-files/${userDirectory}/snippets/haskell.json" "${haskellSnippetsJsonPath}"

      # work profile: global snippets
      #
      assertFileExists "home-files/${userDirectory}/profiles/work/snippets/global.code-snippets"
      assertFileContent "home-files/${userDirectory}/profiles/work/snippets/global.code-snippets" "${globalSnippetsJsonPath}"

      # work profile: elixir snippets
      #
      assertFileExists "home-files/${userDirectory}/profiles/work/snippets/elixir.json"
      assertFileContent "home-files/${userDirectory}/profiles/work/snippets/elixir.json" "${elixirSnippetsJsonPath}"

      # work profile: haskell snippets
      #
      assertFileExists "home-files/${userDirectory}/profiles/work/snippets/haskell.json"
      assertFileContent "home-files/${userDirectory}/profiles/work/snippets/haskell.json" "${haskellSnippetsJsonPath}"

      # the immutable links are not created because the snippets files are immutable by default
      #
      assertPathNotExists "home-files/${userDirectory}/snippets/.immutable-global.code-snippets"
      assertPathNotExists "home-files/${userDirectory}/snippets/.immutable-elixir.json"
      assertPathNotExists "home-files/${userDirectory}/snippets/.immutable-haskell.json"
      assertPathNotExists "home-files/${userDirectory}/profiles/work/snippets/.immutable-global.code-snippets"
      assertPathNotExists "home-files/${userDirectory}/profiles/work/snippets/.immutable-elixir.json"
      assertPathNotExists "home-files/${userDirectory}/profiles/work/snippets/.immutable-haskell.json"
    '';
  };
}
