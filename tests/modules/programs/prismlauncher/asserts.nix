{
  programs.prismlauncher = {
    enable = true;

    themes = {
      foo = ./asserts.nix;
      baz.theme = { };
    };
  };

  test.asserts = {
    assertions.expected = [
      "`programs.prismlauncher.themes.baz.theme` must not be empty."
      "`programs.prismlauncher.themes.foo` must be a directory when set to a path."
    ];
  };
}
