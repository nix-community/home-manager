{ lib }:

let
  inherit (lib)
    defaultFunctor
    hm
    mkIf
    mkOrder
    mkOption
    mkOptionType
    types
    ;

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
      merge = {
        __functor =
          self: loc: defs:
          (self.v2 { inherit loc defs; }).value;
        v2 =
          { loc, defs }:
          # Delegate to submodule's v2 merge to propagate any errors
          submoduleType.merge.v2 {
            inherit loc;
            defs = map (def: {
              inherit (def) file;
              value = maybeConvert def;
            }) defs;
          };
      };
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
      description = "DAG of ${elemType.description}";
      check = {
        __functor = _self: attrEquivalent.check;
        isV2MergeCoherent = true;
      };
      merge = {
        __functor =
          self: loc: defs:
          (self.v2 { inherit loc defs; }).value;
        v2 =
          { loc, defs }:
          # Directly delegate to attrsOf's v2 merge
          attrEquivalent.merge.v2 {
            inherit loc defs;
          };
      };
      inherit (attrEquivalent) emptyValue;
      inherit (elemType) getSubModules;
      getSubOptions = prefix: elemType.getSubOptions (prefix ++ [ "<name>" ]);
      substSubModules = m: dagOf (elemType.substSubModules m);
      functor = (defaultFunctor name) // {
        wrapped = elemType;
      };
      nestedTypes.elemType = elemType;
    };
}
