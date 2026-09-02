{
  programs.qcal.enable = true;
  accounts.calendar.accounts = {
    account.qcal = {
      enable = true;
      settings = {
        Password = "account-secret";
        password = "account-lower-secret";
        PASSWORD = "account-upper-secret";
        "Paſſword" = "account-long-s-secret";
      };
    };
    safe.qcal = {
      enable = true;
      settings = {
        Password = "";
        PasswordCmd = "rbw get calendar";
      };
    };
  };

  test.asserts.warnings.expected = [
    "qcal: `programs.qcal.settings.Calendars[0].PASSWORD` is written to the Nix store. Use `PasswordCmd` to read the credential at runtime."
    "qcal: `programs.qcal.settings.Calendars[0].Password` is written to the Nix store. Use `PasswordCmd` to read the credential at runtime."
    "qcal: `programs.qcal.settings.Calendars[0].Paſſword` is written to the Nix store. Use `PasswordCmd` to read the credential at runtime."
    "qcal: `programs.qcal.settings.Calendars[0].password` is written to the Nix store. Use `PasswordCmd` to read the credential at runtime."
  ];

  nmt.script = ''
    assertFileExists home-files/.config/qcal/config.json
  '';
}
