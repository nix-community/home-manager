{
  programs.discocss = {
    enable = true;
    package = null;
    discordPackage = null;
    discordAlias = false;

    css = ''
      /* Custom Discord theme */
      .theme-dark {
        --background-primary: #2f3136;
        --background-secondary: #36393f;
      }

      .chat-3bRxxu {
        background: var(--background-primary);
      }

      .content-yTz4x3:before {
        content: "Custom CSS Loaded";
        color: #43b581;
      }
    '';
  };

  nmt.script = ''
    assertFileExists home-files/.config/discocss/custom.css
    assertFileContent \
      home-files/.config/discocss/custom.css \
      ${./with-custom-css-expected.css}
  '';
}
