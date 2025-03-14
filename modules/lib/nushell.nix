{ lib }: rec {
  mkNushellInline = expr: lib.setType "nushell-inline" { inherit expr; };

  isNushellInline = lib.isType "nushell-inline";

  toNushell = { indent ? "", multiline ? true, asBindings ? false, }@args:
    v:
    let
      innerIndent = "${indent}    ";
      introSpace = if multiline then ''

        ${innerIndent}'' else
        " ";
      outroSpace = if multiline then ''

        ${indent}'' else
        " ";
      innerArgs = args // {
        indent = if asBindings then indent else innerIndent;
        asBindings = false;
      };
      concatItems = lib.concatStringsSep introSpace;

      generatedBindings = assert lib.assertMsg (badVarNames == [ ])
        "Bad Nushell variable names: ${
          lib.generators.toPretty { } badVarNames
        }";
        lib.concatStrings (lib.mapAttrsToList (key: value: ''
          ${indent}let ${key} = ${toNushell innerArgs value}
        '') v);

      isBadVarName = name:
        # Extracted from https://github.com/nushell/nushell/blob/ebc7b80c23f777f70c5053cca428226b3fe00d30/crates/nu-parser/src/parser.rs#L33
        # Variables with numeric or even empty names are allowed. The only requisite is not containing any of the following characters
        let invalidVariableCharacters = ".[({+-*^/=!<>&|";
        in lib.match "^[$]?[^${lib.escapeRegex invalidVariableCharacters}]+$"
        name == null;
      badVarNames = lib.filter isBadVarName (builtins.attrNames v);
    in if asBindings then
      generatedBindings
    else if v == null then
      "null"
    else if lib.isInt v || lib.isFloat v || lib.isString v || lib.isBool v then
      lib.strings.toJSON v
    else if lib.isList v then
      (if v == [ ] then
        "[]"
      else
        "[${introSpace}${
          concatItems (map (value: "${toNushell innerArgs value}") v)
        }${outroSpace}]")
    else if lib.isAttrs v then
      (if isNushellInline v then
        "(${v.expr})"
      else if v == { } then
        "{}"
      else if lib.isDerivation v then
        toString v
      else
        "{${introSpace}${
          concatItems (lib.mapAttrsToList (key: value:
            "${lib.strings.toJSON key}: ${toNushell innerArgs value}") v)
        }${outroSpace}}")
    else
      abort "nushell.toNushell: type ${lib.typeOf v} is unsupported";
}
