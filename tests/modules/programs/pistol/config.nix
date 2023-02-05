{
  programs.pistol = {
    enable = true;
    config = {
      "text/*" =
        "bat --paging=never --color=always --style=auto --wrap=character --terminal-width=%pistol-extra0% --line-range=1:%pistol-extra1% %pistol-filename%";
      "application/json" =
        "bat --paging=never --color=always --style=auto --wrap=character --terminal-width=%pistol-extra0% --line-range=1:%pistol-extra1% %pistol-filename%";
    };
  };

  test.stubs.pistol = { };

  test.asserts.assertions.expected = [
    (let offendingFile = toString ./config.nix;
    in ''
      The option definition `programs.pistol.config' in `${offendingFile}' no longer has any effect; please remove it.
      Pistol is now configured with programs.pistol.associations.
    '')
  ];
}
