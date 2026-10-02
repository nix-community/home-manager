{
  config,
  pkgs,
  ...
}:

{
  imports = [ ./stubs.nix ];

  programs.opencode = {
    enable = true;
    validation.enable = true;
    themes = {
      dark = {
        theme = {
          primary = {
            dark = "#88C0D0";
            light = "#5E81AC";
          };

          secondary = {
            dark = "#81A1C1";
            light = "#81A1C1";
          };

          accent = {
            dark = "#8FBCBB";
            light = "#8FBCBB";
          };

          error = {
            dark = "#BF616A";
            light = "#BF616A";
          };

          warning = {
            dark = "#D08770";
            light = "#D08770";
          };

          success = {
            dark = "#A3BE8C";
            light = "#A3BE8C";
          };

          info = {
            dark = "#88C0D0";
            light = "#5E81AC";
          };

          text = {
            dark = "#D8DEE9";
            light = "#2E3440";
          };

          textMuted = {
            dark = "#4C566A";
            light = "#3B4252";
          };

          background = {
            dark = "#2E3440";
            light = "#ECEFF4";
          };

          backgroundPanel = {
            dark = "#3B4252";
            light = "#E5E9F0";
          };

          backgroundElement = {
            dark = "#3B4252";
            light = "#D8DEE9";
          };

          border = {
            dark = "#434C5E";
            light = "#4C566A";
          };

          borderActive = {
            dark = "#4C566A";
            light = "#434C5E";
          };

          borderSubtle = {
            dark = "#434C5E";
            light = "#4C566A";
          };

          diffAdded = {
            dark = "#A3BE8C";
            light = "#A3BE8C";
          };

          diffRemoved = {
            dark = "#BF616A";
            light = "#BF616A";
          };

          diffContext = {
            dark = "#4C566A";
            light = "#4C566A";
          };

          diffHunkHeader = {
            dark = "#4C566A";
            light = "#4C566A";
          };

          diffHighlightAdded = {
            dark = "#A3BE8C";
            light = "#A3BE8C";
          };

          diffHighlightRemoved = {
            dark = "#BF616A";
            light = "#BF616A";
          };

          diffAddedBg = {
            dark = "#3B4252";
            light = "#E5E9F0";
          };

          diffRemovedBg = {
            dark = "#3B4252";
            light = "#E5E9F0";
          };

          diffContextBg = {
            dark = "#3B4252";
            light = "#E5E9F0";
          };

          diffLineNumber = {
            dark = "#434C5E";
            light = "#D8DEE9";
          };

          diffAddedLineNumberBg = {
            dark = "#3B4252";
            light = "#E5E9F0";
          };

          diffRemovedLineNumberBg = {
            dark = "#3B4252";
            light = "#E5E9F0";
          };

          markdownText = {
            dark = "#D8DEE9";
            light = "#2E3440";
          };

          markdownHeading = {
            dark = "#88C0D0";
            light = "#5E81AC";
          };

          markdownLink = {
            dark = "#81A1C1";
            light = "#81A1C1";
          };

          markdownLinkText = {
            dark = "#8FBCBB";
            light = "#8FBCBB";
          };

          markdownCode = {
            dark = "#A3BE8C";
            light = "#A3BE8C";
          };

          markdownBlockQuote = {
            dark = "#4C566A";
            light = "#4C566A";
          };

          markdownEmph = {
            dark = "#D08770";
            light = "#D08770";
          };

          markdownStrong = {
            dark = "#EBCB8B";
            light = "#EBCB8B";
          };

          markdownHorizontalRule = {
            dark = "#4C566A";
            light = "#4C566A";
          };

          markdownListItem = {
            dark = "#88C0D0";
            light = "#5E81AC";
          };

          markdownListEnumeration = {
            dark = "#8FBCBB";
            light = "#8FBCBB";
          };

          markdownImage = {
            dark = "#81A1C1";
            light = "#81A1C1";
          };

          markdownImageText = {
            dark = "#8FBCBB";
            light = "#8FBCBB";
          };

          markdownCodeBlock = {
            dark = "#D8DEE9";
            light = "#2E3440";
          };

          syntaxComment = {
            dark = "#4C566A";
            light = "#4C566A";
          };

          syntaxKeyword = {
            dark = "#81A1C1";
            light = "#81A1C1";
          };

          syntaxFunction = {
            dark = "#88C0D0";
            light = "#88C0D0";
          };

          syntaxVariable = {
            dark = "#8FBCBB";
            light = "#8FBCBB";
          };

          syntaxString = {
            dark = "#A3BE8C";
            light = "#A3BE8C";
          };

          syntaxNumber = {
            dark = "#B48EAD";
            light = "#B48EAD";
          };

          syntaxType = {
            dark = "#8FBCBB";
            light = "#8FBCBB";
          };

          syntaxOperator = {
            dark = "#81A1C1";
            light = "#81A1C1";
          };

          syntaxPunctuation = {
            dark = "#D8DEE9";
            light = "#2E3440";
          };
        };
      };
      light = {
        theme = {
          primary = {
            dark = "#88C0D0";
            light = "#5E81AC";
          };

          secondary = {
            dark = "#81A1C1";
            light = "#81A1C1";
          };

          accent = {
            dark = "#8FBCBB";
            light = "#8FBCBB";
          };

          error = {
            dark = "#BF616A";
            light = "#BF616A";
          };

          warning = {
            dark = "#D08770";
            light = "#D08770";
          };

          success = {
            dark = "#A3BE8C";
            light = "#A3BE8C";
          };

          info = {
            dark = "#88C0D0";
            light = "#5E81AC";
          };

          text = {
            dark = "#D8DEE9";
            light = "#2E3440";
          };

          textMuted = {
            dark = "#4C566A";
            light = "#3B4252";
          };

          background = {
            dark = "#2E3440";
            light = "#ECEFF4";
          };

          backgroundPanel = {
            dark = "#3B4252";
            light = "#E5E9F0";
          };

          backgroundElement = {
            dark = "#3B4252";
            light = "#D8DEE9";
          };

          border = {
            dark = "#434C5E";
            light = "#4C566A";
          };

          borderActive = {
            dark = "#4C566A";
            light = "#434C5E";
          };

          borderSubtle = {
            dark = "#434C5E";
            light = "#4C566A";
          };

          diffAdded = {
            dark = "#A3BE8C";
            light = "#A3BE8C";
          };

          diffRemoved = {
            dark = "#BF616A";
            light = "#BF616A";
          };

          diffContext = {
            dark = "#4C566A";
            light = "#4C566A";
          };

          diffHunkHeader = {
            dark = "#4C566A";
            light = "#4C566A";
          };

          diffHighlightAdded = {
            dark = "#A3BE8C";
            light = "#A3BE8C";
          };

          diffHighlightRemoved = {
            dark = "#BF616A";
            light = "#BF616A";
          };

          diffAddedBg = {
            dark = "#3B4252";
            light = "#E5E9F0";
          };

          diffRemovedBg = {
            dark = "#3B4252";
            light = "#E5E9F0";
          };

          diffContextBg = {
            dark = "#3B4252";
            light = "#E5E9F0";
          };

          diffLineNumber = {
            dark = "#434C5E";
            light = "#D8DEE9";
          };

          diffAddedLineNumberBg = {
            dark = "#3B4252";
            light = "#E5E9F0";
          };

          diffRemovedLineNumberBg = {
            dark = "#3B4252";
            light = "#E5E9F0";
          };

          markdownText = {
            dark = "#D8DEE9";
            light = "#2E3440";
          };

          markdownHeading = {
            dark = "#88C0D0";
            light = "#5E81AC";
          };

          markdownLink = {
            dark = "#81A1C1";
            light = "#81A1C1";
          };

          markdownLinkText = {
            dark = "#8FBCBB";
            light = "#8FBCBB";
          };

          markdownCode = {
            dark = "#A3BE8C";
            light = "#A3BE8C";
          };

          markdownBlockQuote = {
            dark = "#4C566A";
            light = "#4C566A";
          };

          markdownEmph = {
            dark = "#D08770";
            light = "#D08770";
          };

          markdownStrong = {
            dark = "#EBCB8B";
            light = "#EBCB8B";
          };

          markdownHorizontalRule = {
            dark = "#4C566A";
            light = "#4C566A";
          };

          markdownListItem = {
            dark = "#88C0D0";
            light = "#5E81AC";
          };

          markdownListEnumeration = {
            dark = "#8FBCBB";
            light = "#8FBCBB";
          };

          markdownImage = {
            dark = "#81A1C1";
            light = "#81A1C1";
          };

          markdownImageText = {
            dark = "#8FBCBB";
            light = "#8FBCBB";
          };

          markdownCodeBlock = {
            dark = "#D8DEE9";
            light = "#2E3440";
          };

          syntaxComment = {
            dark = "#4C566A";
            light = "#4C566A";
          };

          syntaxKeyword = {
            dark = "#81A1C1";
            light = "#81A1C1";
          };

          syntaxFunction = {
            dark = "#88C0D0";
            light = "#88C0D0";
          };

          syntaxVariable = {
            dark = "#8FBCBB";
            light = "#8FBCBB";
          };

          syntaxString = {
            dark = "#A3BE8C";
            light = "#A3BE8C";
          };

          syntaxNumber = {
            dark = "#B48EAD";
            light = "#B48EAD";
          };

          syntaxType = {
            dark = "#8FBCBB";
            light = "#8FBCBB";
          };

          syntaxOperator = {
            dark = "#81A1C1";
            light = "#81A1C1";
          };

          syntaxPunctuation = {
            dark = "#D8DEE9";
            light = "#2E3440";
          };
        };
      };
    };
  };

  nmt.script =
    let
      activationScript = pkgs.writeScript "activation" config.home.activation.validateOpenCodeConfigs.data;
    in
    ''
      assertFileExists "${config.programs.opencode.package.passthru.jsonschema.theme}"

      substitute ${activationScript} $TMPDIR/activate --subst-var TMPDIR
      chmod +x $TMPDIR/activate
      $TMPDIR/activate
    '';
}
