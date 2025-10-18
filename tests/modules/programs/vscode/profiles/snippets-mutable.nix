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

  # when multiple profiles are defined, they are immutable by default.
  # however we can override this to make the profiles mutable
  #
  forkConfig = forkInputs // {
    mutableProfile = true;

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
      # default profile: global snippets
      #
      assertFileExists "home-files/${userDirectory}/snippets/.immutable-global.code-snippets"
      assertFileContent "home-files/${userDirectory}/snippets/.immutable-global.code-snippets" "${globalSnippetsJsonPath}"

      # default profile: elixir snippets
      #
      assertFileExists "home-files/${userDirectory}/snippets/.immutable-elixir.json"
      assertFileContent "home-files/${userDirectory}/snippets/.immutable-elixir.json" "${elixirSnippetsJsonPath}"

      # default profile: haskell snippets
      #
      assertFileExists "home-files/${userDirectory}/snippets/.immutable-haskell.json"
      assertFileContent "home-files/${userDirectory}/snippets/.immutable-haskell.json" "${haskellSnippetsJsonPath}"

      # work profile: global snippets
      #
      assertFileExists "home-files/${userDirectory}/profiles/work/snippets/.immutable-global.code-snippets"
      assertFileContent "home-files/${userDirectory}/profiles/work/snippets/.immutable-global.code-snippets" "${globalSnippetsJsonPath}"

      # work profile: elixir snippets
      #
      assertFileExists "home-files/${userDirectory}/profiles/work/snippets/.immutable-elixir.json"
      assertFileContent "home-files/${userDirectory}/profiles/work/snippets/.immutable-elixir.json" "${elixirSnippetsJsonPath}"

      # work profile: haskell snippets
      #
      assertFileExists "home-files/${userDirectory}/profiles/work/snippets/.immutable-haskell.json"
      assertFileContent "home-files/${userDirectory}/profiles/work/snippets/.immutable-haskell.json" "${haskellSnippetsJsonPath}"

      # mutable copies are created only during activation
      #
      assertPathNotExists "home-files/${userDirectory}/snippets/global.code-snippets"
      assertPathNotExists "home-files/${userDirectory}/snippets/elixir.json"
      assertPathNotExists "home-files/${userDirectory}/snippets/haskell.json"
      assertPathNotExists "home-files/${userDirectory}/profiles/work/snippets/global.json"
      assertPathNotExists "home-files/${userDirectory}/profiles/work/snippets/elixir.json"
      assertPathNotExists "home-files/${userDirectory}/profiles/work/snippets/haskell.json"
    '';
  };
}
