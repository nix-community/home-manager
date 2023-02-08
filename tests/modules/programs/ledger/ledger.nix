{ ... }:

{
  programs.ledger = {
    enable = true;
    settings = {
      sort = "date";
      strict = true;
      pedantic = true;
      leeway = 30;
      date-format = "%Y-%m-%d";
      file = [
        "~/finances/journal.ledger"
        "~/finances/assets.ledger"
        "~/finances/income.ledger"
      ];
    };
  };

  test.stubs.ledger = { };

  nmt.script = ''
    assertFileContent home-files/.config/ledger/ledgerrc \
    ${builtins.toFile "ledger-expected-settings" ''
      --date-format %Y-%m-%d
      --file ~/finances/journal.ledger
      --file ~/finances/assets.ledger
      --file ~/finances/income.ledger
      --leeway 30
      --pedantic
      --sort date
      --strict
    ''}
  '';
}
