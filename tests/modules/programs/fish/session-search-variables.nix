{
  lib,
  realPkgs,
  ...
}:

let
  variables = [
    "ALL_EMPTY"
    "BACKSLASH"
    "BACKTICK"
    "COMMAND"
    "CONSUMED"
    "DUPLICATE"
    "EARLIER"
    "EMPTY_FIELDS"
    "EMPTY_FIELDSPATH"
    "EMPTYPATH"
    "ESCAPED_QUOTE_GLOB"
    "EXPANDED"
    "GLOB"
    "LITERAL"
    "LATER"
    "RUNTIME_EMPTY"
    "RUNTIME_MIXED"
    "SEPARATOR"
    "SHARED"
    "SUBSTRING"
    "TESTPATH"
    "TEST_DIRS"
  ];

  scenarios = [
    {
      name = "first";
      environment = {
        CONSUMED = "configured";
        DUPLICATE = "a:x:a";
        EARLIER = "old";
        EMPTY_ENTRY = "";
        EMPTY_FIELDS = ":middle:";
        EMPTY_FIELDSPATH = ":middle:";
        EMPTYPATH = "";
        LATER = "base";
        SEPARATOR = "x:a:b:y";
        SHARED = "/inherited/shared";
        SUBSTRING = "/usr/share/ubuntu:/usr/share";
        TESTPATH = "/sys/two:/hm/two";
        TEST_DIRS = "/sys/dirs";
      };
      expected = {
        ALL_EMPTY = "";
        BACKSLASH = "tail\\";
        BACKTICK = "backtick";
        COMMAND = "command with space";
        CONSUMED = "configured";
        DUPLICATE = "a:x";
        EARLIER = "configured:old";
        EMPTY_FIELDS = "added::middle:";
        EMPTY_FIELDSPATH = "added::middle:";
        EMPTYPATH = "configured";
        ESCAPED_QUOTE_GLOB = "\"*";
        EXPANDED = "/runtime/home/tools";
        GLOB = "[a-z]";
        LITERAL = "$NOT_EXPANDED/entry";
        LATER = "configured:old:base";
        RUNTIME_EMPTY = "";
        RUNTIME_MIXED = "kept";
        SEPARATOR = "a:b:x:y";
        SHARED = "/inherited/shared:same";
        SUBSTRING = "/usr/share:/usr/share/ubuntu";
        TESTPATH = "/hm/one:/hm/two:/sys/two:/hm/fallback";
        TEST_DIRS = "/hm/dirs:/sys/dirs:/hm/dirs/fallback";
      };
    }
    {
      name = "later";
      environment = {
        CONSUMED = "configured";
        DUPLICATE = "x:a";
        EARLIER = "old:configured";
        EMPTY_ENTRY = "";
        EMPTY_FIELDS = ":middle:added:";
        EMPTY_FIELDSPATH = ":middle:added:";
        EMPTYPATH = "configured";
        LATER = "base";
        SEPARATOR = "x:a:b:y";
        SHARED = "same:/inherited/shared";
        SUBSTRING = "/usr/share/ubuntu:/usr/share";
        TESTPATH = "/sys/two:/hm/two";
        TEST_DIRS = "/sys/dirs:/hm/dirs";
        __HM_SESS_VARS_MERGED = "1";
      };
      expected = {
        ALL_EMPTY = "";
        BACKSLASH = "tail\\";
        BACKTICK = "backtick";
        COMMAND = "command with space";
        CONSUMED = "configured";
        DUPLICATE = "x:a";
        EARLIER = "old:configured";
        EMPTY_FIELDS = ":middle:added:";
        EMPTY_FIELDSPATH = ":middle:added:";
        EMPTYPATH = "configured";
        ESCAPED_QUOTE_GLOB = "\"*";
        EXPANDED = "/runtime/home/tools";
        GLOB = "[a-z]";
        LITERAL = "$NOT_EXPANDED/entry";
        LATER = "old:configured:base";
        RUNTIME_EMPTY = "";
        RUNTIME_MIXED = "kept";
        SEPARATOR = "x:a:b:y";
        SHARED = "same:/inherited/shared";
        SUBSTRING = "/usr/share/ubuntu:/usr/share";
        TESTPATH = "/hm/one:/sys/two:/hm/two:/hm/fallback";
        TEST_DIRS = "/sys/dirs:/hm/dirs:/hm/dirs/fallback";
      };
    }
  ];

  newlineValue = "\nlead\n__HM_SESS_VARS_END\ntrail\n";

  renderExpected =
    expected: lib.concatMapStrings (name: "${name}=set:${expected.${name}}\n") variables;

  environmentArguments =
    environment:
    lib.escapeShellArgs (
      [ "HOME=/runtime/home" ] ++ lib.mapAttrsToList (name: value: "${name}=${value}") environment
    );

  posixProbe = realPkgs.writeShellScript "session-search-variables-posix-probe" ''
    set -eu
    . "$1"

    for name in ${lib.escapeShellArgs variables}; do
      eval "state=\''${$name+x}"
      if [ "$state" = x ]; then
        state=set
        eval "value=\''${$name-}"
      else
        state=unset
        value=
      fi
      printf '%s=%s:%s\n' "$name" "$state" "$value"
    done
  '';

  fishProbe = realPkgs.writeText "session-search-variables-fish-probe.fish" ''
    source $argv[1]

    test (count $TESTPATH) -eq 4
    or begin
        echo "TESTPATH is not a four-element Fish path list" >&2
        exit 1
    end
    test (count $EMPTYPATH) -eq 1
    or begin
        echo "EMPTYPATH did not retain one configured element" >&2
        exit 1
    end
    test (count $EMPTY_FIELDSPATH) -eq 4
    or begin
        echo "EMPTY_FIELDSPATH did not retain its empty field" >&2
        exit 1
    end
    test (count $TEST_DIRS) -eq 1
    or begin
        echo "TEST_DIRS should remain one scalar value" >&2
        exit 1
    end

    for name in ${lib.escapeShellArgs variables}
        if set -q $name
            set state set
            set value (string join : $$name)
        else
            set state unset
            set value ""
        end
        printf '%s=%s:%s\n' $name $state $value
    end

    if functions -q __hm_merge
        echo "__hm_merge was not removed" >&2
        exit 1
    end

    exit 0
  '';

  posixNewlineProbe = realPkgs.writeShellScript "session-search-variables-posix-newline-probe" ''
    set -eu
    . "$1"
    printf '%s\0%s\0' "$NEWLINE_SCALAR" "$NEWLINEPATH"
  '';

  fishNewlineProbe = realPkgs.writeText "session-search-variables-fish-newline-probe.fish" ''
    source $argv[1]
    test (count $NEWLINEPATH) -eq 1
    or exit 1
    printf '%s\0%s\0' "$NEWLINE_SCALAR" "$NEWLINEPATH[1]"
  '';
in
{
  programs.fish.enable = true;

  home.sessionSearchVariables = {
    ALL_EMPTY = [ "" ];
    BACKSLASH = [ "tail\\" ];
    BACKTICK = [ "`printf backtick`" ];
    COMMAND = [ "$(printf \"%s\" \"command with space\")" ];
    CONSUMED = [ "configured" ];
    DUPLICATE = [
      "a"
      "a"
    ];
    EARLIER = [ "configured" ];
    EMPTY_FIELDS = [ "added" ];
    EMPTY_FIELDSPATH = [ "added" ];
    EMPTYPATH = [ "configured" ];
    ESCAPED_QUOTE_GLOB = [ "\\\"*" ];
    EXPANDED = [ "$HOME/tools" ];
    GLOB = [ "[a-z]" ];
    LITERAL = [ "\\$NOT_EXPANDED/entry" ];
    LATER = [ "$EARLIER" ];
    NEWLINEPATH = [ newlineValue ];
    NEWLINE_SCALAR = [ newlineValue ];
    RUNTIME_EMPTY = [ "$EMPTY_ENTRY" ];
    RUNTIME_MIXED = [
      "kept"
      "$EMPTY_ENTRY"
    ];
    SEPARATOR = [ "a:b" ];
    SHARED = [ "same" ];
    SUBSTRING = [ "/usr/share" ];
    TESTPATH = [
      "/hm/one"
      "/hm/two"
    ];
    TEST_DIRS = [ "/hm/dirs" ];
  };

  test.asserts.warnings.expected = [
    ''
      `home.sessionPath`, `home.sessionSearchVariables`, or
      `home.sessionSearchVariablesAppend` contains an empty entry, which Home
      Manager ignores. Write `.` to include the current directory. If the
      empty entry has tool-specific meaning, set the complete value through
      `home.sessionVariables` instead.
    ''
  ];

  home.sessionSearchVariablesAppend = {
    SHARED = [ "same" ];
    TESTPATH = [ "/hm/fallback" ];
    TEST_DIRS = [ "/hm/dirs/fallback" ];
  };

  nmt.script = ''
    posixSessionVars=home-path/etc/profile.d/hm-session-vars.sh
    fishSessionVars=home-path/etc/profile.d/hm-session-vars.fish
    assertFileExists $posixSessionVars
    assertFileExists $fishSessionVars

    ${lib.concatMapStringsSep "\n" (
      scenario:
      let
        expected = realPkgs.writeText "session-search-variables-${scenario.name}.expected" (
          renderExpected scenario.expected
        );
      in
      ''
        ${realPkgs.coreutils}/bin/env -i ${environmentArguments scenario.environment} \
          ${posixProbe} "$TESTED/$posixSessionVars" > posix-${scenario.name} \
          || fail "POSIX ${scenario.name} probe failed"
        ${realPkgs.coreutils}/bin/env -i ${environmentArguments scenario.environment} \
          ${realPkgs.fish}/bin/fish --no-config ${fishProbe} \
          "$TESTED/$fishSessionVars" > fish-${scenario.name} \
          || fail "Fish ${scenario.name} probe failed"

        ${realPkgs.diffutils}/bin/diff -u ${expected} posix-${scenario.name} \
          || fail "POSIX ${scenario.name}-merge output was incorrect"
        ${realPkgs.diffutils}/bin/diff -u posix-${scenario.name} fish-${scenario.name} \
          || fail "POSIX and Fish ${scenario.name}-merge output differed"
      ''
    ) scenarios}

    printf '%s\0%s\0' ${lib.escapeShellArg newlineValue} ${lib.escapeShellArg newlineValue} \
      > newline.expected

    for marker in first later; do
      markerArgs=()
      if [[ $marker == later ]]; then
        markerArgs+=(__HM_SESS_VARS_MERGED=1)
      fi

      ${realPkgs.coreutils}/bin/env -i HOME=/runtime/home EMPTY_ENTRY= EARLIER=old \
        "''${markerArgs[@]}" \
        ${lib.escapeShellArg "NEWLINE_SCALAR=${newlineValue}"} \
        ${lib.escapeShellArg "NEWLINEPATH=${newlineValue}"} \
        ${posixNewlineProbe} "$TESTED/$posixSessionVars" > newline-posix-$marker \
        || fail "POSIX $marker newline probe failed"
      ${realPkgs.coreutils}/bin/env -i HOME=/runtime/home EMPTY_ENTRY= EARLIER=old \
        "''${markerArgs[@]}" \
        ${lib.escapeShellArg "NEWLINE_SCALAR=${newlineValue}"} \
        ${lib.escapeShellArg "NEWLINEPATH=${newlineValue}"} \
        ${realPkgs.fish}/bin/fish --no-config ${fishNewlineProbe} \
        "$TESTED/$fishSessionVars" > newline-fish-$marker \
        || fail "Fish $marker newline probe failed"

      ${realPkgs.diffutils}/bin/cmp newline.expected newline-posix-$marker \
        || fail "POSIX $marker merge changed newline-bearing entries"
      ${realPkgs.diffutils}/bin/cmp newline-posix-$marker newline-fish-$marker \
        || fail "POSIX and Fish $marker newline output differed"
    done
  '';
}
