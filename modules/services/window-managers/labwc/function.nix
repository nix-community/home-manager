{ lib, ... }:

let
  # Escape XML special characters (e.g., <, >, &, etc.)
  escape = lib.escapeXML;

  # Indent each non-empty line of the given text by `level` using two spaces per level.
  indent =
    level: text:
    let
      indentation = lib.concatStrings (lib.genList (_: "  ") level); # Two spaces per level
      lines = lib.splitString "\n" text; # Split text into lines
      indentedLines = map (line: if line == "" then "" else "${indentation}${line}") lines;
    in
    lib.concatStringsSep "\n" indentedLines;

  # Generate a <menu> or <item> or <separator> XML entry based on a menu item definition
  generateMenu =
    item:
    if item ? separator then
      let
        labelAttr = if item.separator ? label then " label=\"${escape item.separator.label}\"" else "";
      in
      "<separator${labelAttr} />"

    else if item ? menuId then
      let
        idAttr = " id=\"${escape item.menuId}\"";
        labelAttr = if item ? label then " label=\"${escape item.label}\"" else "";
        iconAttr = if item ? icon then " icon=\"${escape item.icon}\"" else "";
        children = if item ? items then lib.concatMapStringsSep "\n" generateMenu item.items else "";
        executeAttr = if item ? execute then " execute=\"${escape item.execute}\"" else "";
        outputMenu =
          if item ? execute || children == "" then
            "<menu${idAttr}${labelAttr}${iconAttr}${executeAttr} />"
          else
            "<menu${idAttr}${labelAttr}${iconAttr}${executeAttr}>\n${indent 1 children}\n</menu>";
      in
      outputMenu

    else
      let
        labelAttr = " label=\"${escape item.label}\"";
        iconAttr = if item ? icon then " icon=\"${escape item.icon}\"" else "";
        action = item.action;
        nameAttr = " name=\"${escape action.name}\"";
        toAttr = if action ? to then " to=\"${escape action.to}\"" else "";
        commandAttr = if action ? command then " command=\"${escape action.command}\"" else "";
      in
      "<item${labelAttr}${iconAttr}>\n  <action${nameAttr}${toAttr}${commandAttr} />\n</item>";

  # Get keys in a preferred order
  orderedKeys =
    name: keys:
    let
      # Define key orderings for known structures
      tagOrder = {
        font = [ "@place" ];
        keyboard = [ "default" ];
        mouse = [ "default" ];
        action = [ "@name" ];
        mousebind = [ "@button" ];
      };
      preferred = lib.attrByPath [ name ] [ ] tagOrder;
      cmp =
        a: b:
        let
          ia = lib.lists.findFirstIndex (x: x == a) (-1) preferred;
          ib = lib.lists.findFirstIndex (x: x == b) (-1) preferred;
        in
        if ia == -1 && ib == -1 then
          builtins.lessThan a b
        else if ia == -1 then
          false
        else if ib == -1 then
          true
        else
          builtins.lessThan ia ib;
    in
    builtins.sort cmp keys;

  generateRc =
    name: value:
    # If the value is an attribute set (i.e., a record / dictionary)
    if builtins.isAttrs value then
      let
        # keys = builtins.attrNames value;
        keys = orderedKeys name (builtins.attrNames value);

        attrKeys = builtins.filter (k: lib.hasPrefix "@" k) keys;
        childKeys = builtins.filter (k: !(lib.hasPrefix "@" k)) keys;

        # Generate string of XML attributes from keys like "@id" → id="value"
        attrs = lib.concatStrings (
          map (
            k:
            let
              attrName = builtins.substring 1 999 k; # Remove "@" prefix
              attrValue = value.${k};
            in
            " ${attrName}=\"${escape (builtins.toString attrValue)}\""
          ) attrKeys
        );

        # Recursively convert children to XML, with increased indentation
        children = lib.concatStringsSep "\n" (map (k: generateRc k value.${k}) childKeys);
      in

      if children == "" then
        # Only attributes — use self-closing tag with attributes
        "<${name}${attrs} />"

      else
        # Attributes and/or children — use full open/close tag
        "<${name}${attrs}>\n${indent 1 children}\n</${name}>"

    # If the value is a boolean `true`, render as self-closing tag
    else if builtins.isBool value && value then
      "<${name} />"

    # If the value is a list, emit the same tag name for each item
    else if builtins.isList value then
      # Reuse the same tag name for each list item
      lib.concatStringsSep "\n" (map (v: generateRc name v) value)

    # All other primitive values: wrap in start/end tag
    else
      "<${name}>${escape (builtins.toString value)}</${name}>";

  generateXML = name: config: extraConfig: ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!-- ### This file was generated with Nix. Don't modify this file directly. -->
    <${name}>
    ${indent 1 (
      lib.concatStringsSep "\n" (
        (
          if name == "openbox_menu" then
            map generateMenu
          else if name == "labwc_config" then
            lib.mapAttrsToList generateRc
          else
            builtins.throw "error ${name} is neither openbox_menu nor labwc_config"
        )
          config
      )
    )}
    ${indent 1 extraConfig}
    </${name}>
  '';

in
{
  generateXML = generateXML;
}
