{ lib, config, ... }:

let
  syntaxType = lib.types.either (
    lib.types.path
    // {
      # Since our type is string‐like, we have to exclude it from
      # `lib.types.path` to avoid it getting coerced, which could
      # blow up when `lib.types.path` converts it to a string.
      check = x: x._type or null != "home-path" && lib.types.path.check x;
    }
  ) (lib.types.strMatching "~(/.*)?");

  show = lib.generators.toPretty { multiline = false; };

  # Yes, this means that `home.homeDirectory`’s type depends on
  # its value. Try not to think too hard about it.
  homeDirectory =
    if config.home.homeDirectory.syntax == "~" then null else config.home.homeDirectory.syntax;

  parse =
    input:
    assert lib.assertMsg (syntaxType.check input)
      "config.lib.homePath.parse: ${show input} is not a valid absolute or home‐relative path";
    let
      # We accept actual Nix path values for backwards compatibility,
      # but don’t want to copy them into the store.
      syntax = toString input;

      render =
        prefix: handleSuffix:
        let
          suffix = lib.removePrefix "~" syntax;
        in
        if syntax != suffix then prefix + handleSuffix suffix else handleSuffix syntax;
    in
    {
      _type = "home-path";

      inherit syntax render;

      # Check equality against another absolute or home‐relative path,
      # in string or object form.
      #
      # Doesn’t consider `~/foo` to equal `${homeDirectory}/foo`.
      equals =
        other:
        let
          other' = if lib.isString other then parse other else other;
        in
        assert lib.assertMsg (
          other'._type or null == "home-path"
        ) "config.lib.homePath.equals: ${show other} is not a valid absolute or home‐relative path";
        syntax == other'.syntax;

      # Append a relative path.
      join =
        relPath:
        assert lib.assertMsg (
          !(lib.hasPrefix "/" relPath || lib.hasPrefix "~" relPath)
        ) "config.lib.homePath.join: ${show relPath} is not a valid absolute or home‐relative path";
        parse "${syntax}/${relPath}";

      isAbsolute = lib.hasPrefix "/" syntax;

      # Render an absolute path if possible, or `null` if the path is
      # home‐relative and the home directory is not statically known.
      tryAbsolute =
        let
          suffix = lib.removePrefix "~" syntax;
        in
        if syntax != suffix then if homeDirectory == null then null else homeDirectory + suffix else syntax;

      # Render an absolute path if possible, throwing if the path is
      # home‐relative and the home directory is not statically known.
      absolute = render (
        if homeDirectory == null then
          throw (
            lib.concatStrings [
              "Failed to expand ${show syntax} into an absolute path. This is "
              "usually caused by modules that are not compatible with "
              "relocatable configurations interpolating a path into a string."
            ]
          )
        else
          homeDirectory
      ) (suffix: suffix);

      # Render the path relative to the home directory.
      #
      # Note that this collapses both `~` and `~/` to the empty string.
      # We could have something that errors out on absolute paths and
      # preserves the leading slash for relative ones, or add e.g.
      # `cwdRelative` that would represent `~` as `.` and `~/foo` as
      # `./foo`, but there is currently nothing that would use them.
      relative =
        let
          suffixTilde = lib.removePrefix "~" syntax;
          suffixExplicit = lib.removePrefix homeDirectory syntax;
        in
        if syntax != suffixTilde then
          lib.removePrefix "/" suffixTilde
        else if homeDirectory != null && syntax != suffixExplicit then
          lib.removePrefix "/" suffixExplicit
        else
          syntax;

      # Render the path for inclusion in a shell script, like
      # `lib.escapeShellArg`.
      #
      # This should work with both POSIX‐compatible shells and fish
      # (which does not support the `${HOME}` syntax).
      shell = render ''"$HOME"'' lib.escapeShellArg;

      # Render the path for inclusion in an {manpage}`environment.d(5)`
      # definition or a `home.sessionVariables`‐format option.
      environment = render "\${HOME}" (lib.replaceStrings [ "$" "\\" ] [ "\\$" "\\\\" ]);

      # Render the path for inclusion in a specifier‐resolving
      # {manpage}`systemd.unit(5)` field.
      #
      # Note that handling quoting and escaping of whitespace and other
      # special characters, such as for use with `Environment=`, is
      # left to the user.
      systemd = render "%h" (lib.replaceStrings [ "%" ] [ "%%" ]);

      # Render an absolute path for string interpolation to preserve
      # backwards compatibility.
      __toString = self: self.absolute;

      # Render the input syntax for option documentation and
      # `lib.generators.toPretty`.
      __pretty = _: syntax;
      val = null;
    };

  finalType = lib.mkOptionType {
    name = "absolute or home‐relative path";
    descriptionClass = "conjunction";
    check = x: x._type or null == "home-path";
    merge =
      loc: defs:
      lib.seq (lib.mergeEqualOption loc (
        map (def: def // { value = def.value.syntax; }) defs
      )) (lib.head defs).value;
  };

  type = lib.types.coercedTo syntaxType parse finalType // {
    inherit (finalType) description descriptionClass;
  };
in

{
  meta.maintainers = [ lib.maintainers.emily ];

  config.lib.homePath = {
    inherit parse type;
  };
}
