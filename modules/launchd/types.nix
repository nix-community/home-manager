# launchd option type from nix-darwin
#
# Original code from https://github.com/LnL7/nix-darwin/commit/861af0fc94df9454f4e92d6892f75588763164bb

{ lib, ... }:

let
  inherit (lib)
    imap1
    types
    mkOption
    showOption
    mergeDefinitions
    ;
  inherit (builtins)
    map
    filter
    length
    deepSeq
    throw
    toString
    concatLists
    ;
  inherit (lib.options) showDefs;
  wildcardText = lib.literalMD "`*`";

  /*
    *
    A type of list which does not allow duplicate elements. The base/inner
    list type to use (e.g. `types.listOf` or `types.nonEmptyListOf`) is passed
    via argument `listType`, which must be the final type and not a function.

    NOTE: The extra check for duplicates is quadratic and strict, so use this
    type sparingly and only:

      * when needed, and
      * when the list is expected to be recursively short (e.g. < 10 elements)
        and shallow (i.e. strict evaluation of the list won't take too long)

    The implementation of this function is similar to that of
    `types.nonEmptyListOf`.
  */
  types'.uniqueList =
    listType:
    listType
    // {
      description = "unique ${types.optionDescriptionPhrase (class: class == "noun") listType}";
      substSubModules = m: types'.uniqueList (listType.substSubModules m);
      # This has been taken from the implementation of `types.listOf`, but has
      # been modified to throw on duplicates. This check cannot be done in the
      # `check` fn as this check is deep/strict, and because `check` runs
      # prior to merging.
      merge =
        loc: defs:
        let
          # Each element of `dupes` is a list. When there are duplicates,
          # later lists will be duplicates of earlier lists, so just throw on
          # the first set of duplicates found so that we don't have duplicate
          # error msgs.
          checked = filter (
            li:
            if length li > 1 then
              throw ''
                The option `${showOption loc}' contains duplicate entries after merging:
                ${showDefs li}''
            else
              false
          ) dupes;
          dupes = map (def: filter (def': def'.value == def.value) merged) merged;
          merged = filter (x: x ? value) (
            concatLists (
              imap1 (
                n: def:
                imap1 (
                  m: el:
                  let
                    inherit (def) file;
                    loc' = loc ++ [ "[definition ${toString n}-entry ${toString m}]" ];
                  in
                  (mergeDefinitions loc' listType.nestedTypes.elemType [
                    {
                      inherit file;
                      value = el;
                    }
                  ]).optionalValue
                  // {
                    inherit loc' file;
                  }
                ) def.value
              ) defs
            )
          );
        in
        deepSeq checked (map (x: x.value) merged);
    };
in
{
  StartCalendarInterval =
    let
      CalendarIntervalEntry = types.submodule {
        options = {
          Minute = mkOption {
            type = types.nullOr (types.ints.between 0 59);
            default = null;
            defaultText = wildcardText;
            description = ''
              The minute on which this job will be run.
            '';
          };

          Hour = mkOption {
            type = types.nullOr (types.ints.between 0 23);
            default = null;
            defaultText = wildcardText;
            description = ''
              The hour on which this job will be run.
            '';
          };

          Day = mkOption {
            type = types.nullOr (types.ints.between 1 31);
            default = null;
            defaultText = wildcardText;
            description = ''
              The day on which this job will be run.
            '';
          };

          Weekday = mkOption {
            type = types.nullOr (types.ints.between 0 7);
            default = null;
            defaultText = wildcardText;
            description = ''
              The weekday on which this job will be run (0 and 7 are Sunday).
            '';
          };

          Month = mkOption {
            type = types.nullOr (types.ints.between 1 12);
            default = null;
            defaultText = wildcardText;
            description = ''
              The month on which this job will be run.
            '';
          };
        };
      };
    in
    types.either CalendarIntervalEntry (types'.uniqueList (types.nonEmptyListOf CalendarIntervalEntry));
}
