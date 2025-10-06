{ lib }:

let

  mkShellIntegrationOption =
    name:
    {
      config,
      baseName ? name,
      extraDescription ? "",
    }:
    let
      attrName = "enable${baseName}Integration";
    in
    lib.mkOption {
      default = config.home.shell.${attrName};
      defaultText = lib.literalMD "[](#opt-home.shell.${attrName})";
      example = false;
      description = "Whether to enable ${name} integration.${
        lib.optionalString (extraDescription != "") ("\n\n" + extraDescription)
      }";
      type = lib.types.bool;
    };

in
rec {
  # Produces a Bourne shell like statement that prepend new values to
  # an possibly existing variable, using sep(arator).
  # Example:
  #   prependToVar ":" "PATH" [ "$HOME/bin" "$HOME/.local/bin" ]
  #   => "$HOME/bin:$HOME/.local/bin:${PATH:+:}\$PATH"
  prependToVar =
    sep: n: v:
    "${lib.concatStringsSep sep v}\${${n}:+${sep}}\$${n}";

  # Produces a Bourne shell like variable export statement.
  export = n: v: ''export ${n}="${toString v}"'';

  # Given an attribute set containing shell variable names and their
  # assignment, this function produces a string containing an export
  # statement for each set entry.
  exportAll = vars: lib.concatStringsSep "\n" (lib.mapAttrsToList export vars);

  # Wrap a list of strings to a given line width.
  # Packs as many items as possible per line without exceeding maxWidth.
  # Returns a list of strings, each representing a line.
  #
  # Example: wrapLines ["item1" "item2" "very-long-item" "item3"] 20
  #   => ["item1 item2" "very-long-item" "item3"]
  wrapLines =
    items: maxWidth:
    let
      step =
        acc: item:
        let
          potentialLine = if acc.currentLine == "" then item else "${acc.currentLine} ${item}";
        in
        if lib.stringLength potentialLine <= maxWidth then
          acc // { currentLine = potentialLine; }
        else
          acc
          // {
            finishedLines = acc.finishedLines ++ [ acc.currentLine ];
            currentLine = item;
          };
      foldResult = lib.foldl' step {
        finishedLines = [ ];
        currentLine = "";
      } items;
    in
    foldResult.finishedLines ++ lib.optional (foldResult.currentLine != "") foldResult.currentLine;

  # Formats a list of items for shell array content with intelligent width optimization.
  # IMPORTANT: This formats the CONTENTS of an array (what goes inside parentheses),
  # not a complete array definition. Use lib.hm.zsh.define for complete definitions.
  #
  # Uses lib.escapeShellArg for robust shell escaping (handles spaces, quotes, special chars).
  # Packs multiple items per line to optimize terminal width (~78 chars per line).
  # Short arrays (≤3 items, ≤80 chars total) use single-line format.
  #
  # Example outputs:
  #   Empty:       ""
  #   Simple:      item1 item2 item3
  #   With spaces: 'item one' 'item two' 'item three'
  #   Long arrays: \n  item1 item2 item3\n  item4 item5\n
  #
  # Built from composable helpers: wrapLines, formatMultiLine
  formatShellArrayContent =
    items:
    let
      quotedItems = lib.map lib.escapeShellArg items;
      formatMultiLine = lines: "\n  ${lib.concatStringsSep "\n  " lines}\n";
      wrapped = wrapLines quotedItems 78;
    in
    formatMultiLine wrapped;

  mkBashIntegrationOption = mkShellIntegrationOption "Bash";
  mkFishIntegrationOption = mkShellIntegrationOption "Fish";
  mkIonIntegrationOption = mkShellIntegrationOption "Ion";
  mkNushellIntegrationOption = mkShellIntegrationOption "Nushell";
  mkZshIntegrationOption = mkShellIntegrationOption "Zsh";
}
