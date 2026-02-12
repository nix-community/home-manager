{ config, ... }:

{
  programs = {
    pay-respects = {
      enable = true;
      package = config.lib.test.mkStubPackage { };
      rules = {
        cargo = {
          command = "cargo";
          match_err = [
            {
              pattern = [ "run `cargo init` to initialize a new rust project" ];
              suggest = [ "cargo init" ];
            }
          ];
        };

        _PR_GENERAL = {
          match_err = [
            {
              pattern = [ "permission denied" ];
              suggest = [
                ''
                  #[executable(sudo), !cmd_contains(sudo)]
                  sudo {{command}}
                ''
              ];
            }
          ];
        };
      };
    };
  };

  nmt.script = ''
    assertFileContent \
      "home-files/.config/pay-respects/rules/cargo.toml" \
      ${./cargo-expected.toml}

    assertFileContent \
      "home-files/.config/pay-respects/rules/_PR_GENERAL.toml" \
      ${./general-expected.toml}
  '';
}
