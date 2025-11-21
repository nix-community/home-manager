{ config, ... }:
{
  programs.helix = {
    enable = true;

    settings = {
      theme = "base16";
      editor = {
        line-number = "relative";
        lsp.display-messages = true;
      };
      keys.normal = {
        space.space = "file_picker";
        space.w = ":w";
        space.q = ":q";
        esc = [
          "collapse_selection"
          "keep_primary_selection"
        ];
      };
    };

    extraConfig = ''
      [keys.normal.G]
      G = "goto_file_end"
      g = "goto_file_start"
    '';

    languages = {
      language-server.typescript-language-server =
        let
          typescript-language-server = config.lib.test.mkStubPackage {
            outPath = "@typescript-language-server@";
          };
          typescript = config.lib.test.mkStubPackage { outPath = "@typescript@"; };
        in
        {
          command = "${typescript-language-server}/bin/typescript-language-server";
          args = [
            "--stdio"
            "--tsserver-path=${typescript}/lib/node_modules/typescript/lib"
          ];
        };

      language = [
        {
          name = "rust";
          auto-format = false;
        }
      ];
    };

    ignores = [
      ".build/"
      "!.gitignore"
    ];

    themes = {
      base16 =
        let
          transparent = "none";
          gray = "#665c54";
          dark-gray = "#3c3836";
          white = "#fbf1c7";
          black = "#282828";
          red = "#fb4934";
          green = "#b8bb26";
          yellow = "#fabd2f";
          orange = "#fe8019";
          blue = "#83a598";
          magenta = "#d3869b";
          cyan = "#8ec07c";
        in
        {
          "ui.menu" = transparent;
          "ui.menu.selected" = {
            modifiers = [ "reversed" ];
          };
          "ui.linenr" = {
            fg = gray;
            bg = dark-gray;
          };
          "ui.popup" = {
            modifiers = [ "reversed" ];
          };
          "ui.linenr.selected" = {
            fg = white;
            bg = black;
            modifiers = [ "bold" ];
          };
          "ui.selection" = {
            fg = black;
            bg = blue;
          };
          "ui.selection.primary" = {
            modifiers = [ "reversed" ];
          };
          "comment" = {
            fg = gray;
          };
          "ui.statusline" = {
            fg = white;
            bg = dark-gray;
          };
          "ui.statusline.inactive" = {
            fg = dark-gray;
            bg = white;
          };
          "ui.help" = {
            fg = dark-gray;
            bg = white;
          };
          "ui.cursor" = {
            modifiers = [ "reversed" ];
          };
          "variable" = red;
          "variable.builtin" = orange;
          "constant.numeric" = orange;
          "constant" = orange;
          "attributes" = yellow;
          "type" = yellow;
          "ui.cursor.match" = {
            fg = yellow;
            modifiers = [ "underlined" ];
          };
          "string" = green;
          "variable.other.member" = red;
          "constant.character.escape" = cyan;
          "function" = blue;
          "constructor" = blue;
          "special" = blue;
          "keyword" = magenta;
          "label" = magenta;
          "namespace" = blue;
          "diff.plus" = green;
          "diff.delta" = yellow;
          "diff.minus" = red;
          "diagnostic" = {
            modifiers = [ "underlined" ];
          };
          "ui.gutter" = {
            bg = black;
          };
          "info" = blue;
          "hint" = dark-gray;
          "debug" = dark-gray;
          "warning" = yellow;
          "error" = red;
        };
      string = ''
        attributes = "#fabd2f"
        constant = "#fe8019"
        "constant.character.escape" = "#8ec07c"
        "constant.numeric" = "#fe8019"
        constructor = "#83a598"
        debug = "#3c3836"
        "diff.delta" = "#fabd2f"
        "diff.minus" = "#fb4934"
        "diff.plus" = "#b8bb26"
        error = "#fb4934"
        function = "#83a598"
        hint = "#3c3836"
        info = "#83a598"
        keyword = "#d3869b"
        label = "#d3869b"
        namespace = "#83a598"
        special = "#83a598"
        string = "#b8bb26"
        type = "#fabd2f"
        "ui.menu" = "none"
        variable = "#fb4934"
        "variable.builtin" = "#fe8019"
        "variable.other.member" = "#fb4934"
        warning = "#fabd2f"

        [comment]
        fg = "#665c54"

        [diagnostic]
        modifiers = ["underlined"]

        ["ui.cursor"]
        modifiers = ["reversed"]

        ["ui.cursor.match"]
        fg = "#fabd2f"
        modifiers = ["underlined"]

        ["ui.gutter"]
        bg = "#282828"

        ["ui.help"]
        bg = "#fbf1c7"
        fg = "#3c3836"

        ["ui.linenr"]
        bg = "#3c3836"
        fg = "#665c54"

        ["ui.linenr.selected"]
        bg = "#282828"
        fg = "#fbf1c7"
        modifiers = ["bold"]

        ["ui.menu.selected"]
        modifiers = ["reversed"]

        ["ui.popup"]
        modifiers = ["reversed"]

        ["ui.selection"]
        bg = "#83a598"
        fg = "#282828"

        ["ui.selection.primary"]
        modifiers = ["reversed"]

        ["ui.statusline"]
        bg = "#3c3836"
        fg = "#fbf1c7"

        ["ui.statusline.inactive"]
        bg = "#fbf1c7"
        fg = "#3c3836"
      '';
      path = ./theme-base16-expected.toml;
    };
  };

  nmt.script = ''
    assertFileContent \
      home-files/.config/helix/config.toml \
      ${./settings-expected.toml}
    assertFileContent \
      home-files/.config/helix/languages.toml \
      ${./languages-expected.toml}
    assertFileContent \
      home-files/.config/helix/ignore \
      ${./ignore-expected}
    assertFileContent \
      home-files/.config/helix/themes/base16.toml \
      ${./theme-base16-expected.toml}
    assertFileContent \
      home-files/.config/helix/themes/string.toml \
      ${./theme-base16-expected.toml}
    assertFileContent \
      home-files/.config/helix/themes/path.toml \
      ${./theme-base16-expected.toml}
  '';
}
