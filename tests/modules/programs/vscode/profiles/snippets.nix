{ forkInputs, lib, ... }@inputs:
let
  inherit (import ../test-helpers.nix inputs)
    elixirSnippetsJsonPath
    elixirSnippetsObject
    globalSnippetsJsonPath
    globalSnippetsObject
    haskellSnippetsJsonPath
    haskellSnippetsObject
    isMutableProfile
    userDirectory
    ;

  forkConfig = forkInputs // {
    profiles = {
      default = {
        snippets = {
          global = globalSnippetsObject;

          languages = {
            elixir = elixirSnippetsJsonPath;
            haskell = haskellSnippetsJsonPath;
          };
        };
      };

      work = {
        snippets = {
          global = globalSnippetsJsonPath;

          languages = {
            elixir = elixirSnippetsObject;
            haskell = haskellSnippetsObject;
          };
        };
      };
    };
  };
in
{
  config = lib.setAttrByPath [ "programs" forkInputs.moduleName ] forkConfig // {
    nmt.script = ''
      # mutable profiles create immutable nix store files and mutable copies on activation
      # immutable profiles create immutable nix store files linked to the files themselves
      #
      if [[ -n "${toString isMutableProfile}" ]]; then
        assertLinkExists "home-files/${userDirectory}/snippets/.immutable-haskell.json"
        assertLinkExists "home-files/${userDirectory}/snippets/.immutable-global.code-snippets"
        assertLinkExists "home-files/${userDirectory}/snippets/.immutable-elixir.json"
        assertFileExists "home-files/${userDirectory}/snippets/.immutable-haskell.json"
        assertFileExists "home-files/${userDirectory}/snippets/.immutable-global.code-snippets"
        assertFileExists "home-files/${userDirectory}/snippets/.immutable-elixir.json"
        assertFileContent "home-files/${userDirectory}/snippets/.immutable-haskell.json" "${haskellSnippetsJsonPath}"
        assertFileContent "home-files/${userDirectory}/snippets/.immutable-global.code-snippets" "${globalSnippetsJsonPath}"
        assertFileContent "home-files/${userDirectory}/snippets/.immutable-elixir.json" "${elixirSnippetsJsonPath}"

        assertLinkExists "home-files/${userDirectory}/profiles/work/snippets/.immutable-haskell.json"
        assertLinkExists "home-files/${userDirectory}/profiles/work/snippets/.immutable-global.code-snippets"
        assertLinkExists "home-files/${userDirectory}/profiles/work/snippets/.immutable-elixir.json"
        assertFileExists "home-files/${userDirectory}/profiles/work/snippets/.immutable-haskell.json"
        assertFileExists "home-files/${userDirectory}/profiles/work/snippets/.immutable-global.code-snippets"
        assertFileExists "home-files/${userDirectory}/profiles/work/snippets/.immutable-elixir.json"
        assertFileContent "home-files/${userDirectory}/profiles/work/snippets/.immutable-haskell.json" "${haskellSnippetsJsonPath}"
        assertFileContent "home-files/${userDirectory}/profiles/work/snippets/.immutable-global.code-snippets" "${globalSnippetsJsonPath}"
        assertFileContent "home-files/${userDirectory}/profiles/work/snippets/.immutable-elixir.json" "${elixirSnippetsJsonPath}"

        # mutable copies are created only during activation
        #
        assertPathNotExists "home-files/${userDirectory}/snippets/global.code-snippets"
        assertPathNotExists "home-files/${userDirectory}/snippets/elixir.json"
        assertPathNotExists "home-files/${userDirectory}/snippets/haskell.json"

        assertPathNotExists "home-files/${userDirectory}/profiles/work/snippets/global.code-snippets"
        assertPathNotExists "home-files/${userDirectory}/profiles/work/snippets/elixir.json"
        assertPathNotExists "home-files/${userDirectory}/profiles/work/snippets/haskell.json"
      else
        assertFileExists "home-files/${userDirectory}/snippets/global.code-snippets"
        assertFileContent "home-files/${userDirectory}/snippets/global.code-snippets" "${globalSnippetsJsonPath}"
        assertFileExists "home-files/${userDirectory}/snippets/elixir.json"
        assertFileContent "home-files/${userDirectory}/snippets/elixir.json" "${elixirSnippetsJsonPath}"
        assertFileExists "home-files/${userDirectory}/snippets/haskell.json"
        assertFileContent "home-files/${userDirectory}/snippets/haskell.json" "${haskellSnippetsJsonPath}"

        assertFileExists "home-files/${userDirectory}/profiles/work/snippets/global.code-snippets"
        assertFileContent "home-files/${userDirectory}/profiles/work/snippets/global.code-snippets" "${globalSnippetsJsonPath}"
        assertFileExists "home-files/${userDirectory}/profiles/work/snippets/elixir.json"
        assertFileContent "home-files/${userDirectory}/profiles/work/snippets/elixir.json" "${elixirSnippetsJsonPath}"
        assertFileExists "home-files/${userDirectory}/profiles/work/snippets/haskell.json"
        assertFileContent "home-files/${userDirectory}/profiles/work/snippets/haskell.json" "${haskellSnippetsJsonPath}"

        # the immutable links are not created because the files are immutable by default
        #
        assertPathNotExists "home-files/${userDirectory}/snippets/.immutable-global.code-snippets"
        assertPathNotExists "home-files/${userDirectory}/snippets/.immutable-elixir.json"
        assertPathNotExists "home-files/${userDirectory}/snippets/.immutable-haskell.json"

        assertPathNotExists "home-files/${userDirectory}/profiles/work/snippets/.immutable-global.code-snippets"
        assertPathNotExists "home-files/${userDirectory}/profiles/work/snippets/.immutable-elixir.json"
        assertPathNotExists "home-files/${userDirectory}/profiles/work/snippets/.immutable-haskell.json"
      fi;
    '';
  };
}
