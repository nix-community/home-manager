{ lib }:

let
  # Preserve shell expansion inside a double-quoted word while making literal
  # backslashes safe. Existing shell escapes keep their meaning.
  escapeDoubleQuoted =
    let
      escapeLiteral = lib.replaceStrings [ "\\" ] [ "\\\\" ];
      handlePart =
        part:
        if lib.isString part then
          escapeLiteral part
        else
          let
            c = lib.head part;
          in
          # Only these characters have backslash escapes inside double quotes.
          if
            lib.elem c [
              "$"
              "\\"
              "\""
              "`"
            ]
          then
            "\\${c}"
          else
            escapeLiteral "\\${c}";
    in
    value: lib.concatMapStrings handlePart (builtins.split ''\\(.)'' value);
in
{
  inherit escapeDoubleQuoted;

  assignDoubleQuoted = name: value: ''${name}="${escapeDoubleQuoted value}"'';
}
