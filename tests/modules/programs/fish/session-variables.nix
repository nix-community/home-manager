{ config, ... }:

{
  config = {
    home.sessionVariables = {
      V1 = "v1";
      V2 = "v2-${config.home.sessionVariables.V1}";
    };

    # Exercise Babelfish translation of idempotent search variables.
    home.sessionPath = [
      "/foo/bin"
      ""
      "/bar/bin"
      "/foo/bin"
    ];
    home.sessionSearchVariables = {
      GLOB_BACKSLASH = [ "$BACKSLASH_ENTRY" ];
      GLOB_BRACKET = [ "$BRACKET_ENTRY" ];
      GLOB_NEWLINE = [ "$NEWLINE_ENTRY" ];
      GLOB_QUESTION = [ "$QUESTION_ENTRY" ];
      GLOB_STAR = [ "$STAR_ENTRY" ];
      GLOB_STATIC = [ "/literal*" ];
    };
    home.sessionSearchVariablesAppend.GLOB_APPEND = [
      "$STAR_ENTRY"
      "/literal*"
    ];

    programs.fish.enable = true;

    nmt.script = ''
      assertFileExists home-path/etc/profile.d/hm-session-vars.fish

      fish=${config.programs.fish.package}/bin/fish
      sessionVars=$TESTED/home-path/etc/profile.d/hm-session-vars.fish
      "$fish" --no-config -c '
        set -gx PATH /existing /bar/bin /tail
        set -gx STAR_ENTRY "/opt/bin*"
        set -gx QUESTION_ENTRY "/opt/bin?"
        set -gx BRACKET_ENTRY "/opt/bin[ab]"
        set -gx BACKSLASH_ENTRY "/opt/bin\\name"
        set -gx NEWLINE_ENTRY (printf "line\nbreak" | string collect)
        set -gx GLOB_STAR "/opt/bin-foo"
        set -gx GLOB_QUESTION "/opt/bina"
        set -gx GLOB_BRACKET "/opt/bina"
        set -gx GLOB_BACKSLASH "/opt/binname"
        set -gx GLOB_APPEND "/head"
        set -gx GLOB_NEWLINE "lineXbreak"
        set -gx GLOB_STATIC "/literal-match"
        set -g __hm_cur keep-cur
        set -g __hm_add keep-add
        set -g __hm_entry keep-entry
        source $argv[1]
        test "$V1:$V2" = "v1:v2-v1"
        or begin
          echo "plain variables were translated incorrectly"
          exit 1
        end
        set actual (string join : $PATH)
        test "$actual" = "/foo/bin:/existing:/bar/bin:/tail"
        or begin
          echo "after first source: $actual"
          exit 1
        end
        test "$GLOB_STAR" = "$STAR_ENTRY:/opt/bin-foo"
        and test "$GLOB_QUESTION" = "$QUESTION_ENTRY:/opt/bina"
        and test "$GLOB_BRACKET" = "$BRACKET_ENTRY:/opt/bina"
        and test "$GLOB_BACKSLASH" = "$BACKSLASH_ENTRY:/opt/binname"
        and test "$GLOB_APPEND" = "/head:$STAR_ENTRY:/literal*"
        and test "$GLOB_NEWLINE" = "$NEWLINE_ENTRY:lineXbreak"
        and test "$GLOB_STATIC" = "/literal*:/literal-match"
        or begin
          echo "literal Fish membership failed"
          exit 1
        end
        test "$__hm_cur:$__hm_add:$__hm_entry" = "keep-cur:keep-add:keep-entry"
        or begin
          echo "merge scratch globals were clobbered"
          exit 1
        end
        source $argv[1]
        set actual (string join : $PATH)
        test "$actual" = "/foo/bin:/existing:/bar/bin:/tail"
        or begin
          echo "after re-source: $actual"
          exit 1
        end
        test "$GLOB_STAR" = "$STAR_ENTRY:/opt/bin-foo"
        and test "$GLOB_QUESTION" = "$QUESTION_ENTRY:/opt/bina"
        and test "$GLOB_BRACKET" = "$BRACKET_ENTRY:/opt/bina"
        and test "$GLOB_BACKSLASH" = "$BACKSLASH_ENTRY:/opt/binname"
        and test "$GLOB_APPEND" = "/head:$STAR_ENTRY:/literal*"
        and test "$GLOB_NEWLINE" = "$NEWLINE_ENTRY:lineXbreak"
        and test "$GLOB_STATIC" = "/literal*:/literal-match"
        and test "$__hm_cur:$__hm_add:$__hm_entry" = "keep-cur:keep-add:keep-entry"
        or begin
          echo "translated Fish values changed after re-source"
          exit 1
        end
      ' "$sessionVars" || fail "translated Fish session variables are not idempotent"
    '';
  };
}
