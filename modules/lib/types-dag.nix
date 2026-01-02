{ lib }:

let
  inherit (lib)
    hm
    mkIf
    mkOrder
    mkOption
    mkOptionType
    types
    ;

  # Modified from nixpkgs/lib/types.nix https://github.com/NixOS/nixpkgs/blob/821647d8479ce41cafa8294de5abc081e87151e2/lib/types.nix#L84
  # defers type merging to the elemType
  elemTypeFunctor = type: name: payload: {
    inherit payload type name;
    binOp =
      a: b:
      let
        merged = a.elemType.typeMerge b.elemType.functor;
      in
      if merged == null then null else { elemType = merged; };
  };
  dagEntryOf =
    elemType:
    let
      submoduleType = types.submodule (
        { name, ... }:
        {
          options = {
            data = mkOption { type = elemType; };
            after = mkOption { type = with types; listOf str; };
            before = mkOption { type = with types; listOf str; };
          };
          config = mkIf (elemType.name == "submodule") {
            data._module.args.dagName = name;
          };
        }
      );
      maybeConvert =
        def:
        if hm.dag.isEntry def.value then
          def.value
        else
          hm.dag.entryAnywhere (if def ? priority then mkOrder def.priority def.value else def.value);
    in
    mkOptionType {
      name = "dagEntryOf";
      description = "DAG entry of ${elemType.description}";
      # leave the checking to the submodule type
      merge =
        loc: defs:
        submoduleType.merge loc (
          map (def: {
            inherit (def) file;
            value = maybeConvert def;
          }) defs
        );
    };

in
rec {
  # A directed acyclic graph of some inner type.
  #
  # Note, if the element type is a submodule then the `name` argument
  # will always be set to the string "data" since it picks up the
  # internal structure of the DAG values. To give access to the
  # "actual" attribute name a new submodule argument is provided with
  # the name `dagName`.
  dagOf =
    elemType:
    let
      attrEquivalent = types.attrsOf (dagEntryOf elemType);
    in
    mkOptionType rec {
      name = "dagOf";
      description = "DAG of ${
        types.optionDescriptionPhrase (class: class == "noun" || class == "composite") elemType
      }";
      descriptionClass = "composite";
      inherit (attrEquivalent) check merge emptyValue;
      getSubOptions = prefix: elemType.getSubOptions (prefix ++ [ "<name>" ]);
      getSubModules = elemType.getSubModules;
      substSubModules = m: dagOf (elemType.substSubModules m);
      # Allow type merging for elemType
      functor = (elemTypeFunctor dagOf name { inherit elemType; }) // {
        type = payload: dagOf payload.elemType;
      };
      nestedTypes.elemType = elemType;
    };
}
