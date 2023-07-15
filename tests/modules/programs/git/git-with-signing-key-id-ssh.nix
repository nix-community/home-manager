{ pkgs, ... }: {
  config = {
    programs.git = {
      enable = true;
      userName = "John Doe";
      userEmail = "user@example.org";

      signing.signByDefault = true;
      signing.ssh = {
        enable = true;
        program = "path-to-ssh";
        key =
          "ssh-ed25519 ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/ user@example.org";
        defaultKeyCommand = "path-to-key-provider";
      };
    };

    nmt.script = ''
      assertFileExists home-files/.config/git/config
      assertFileContent home-files/.config/git/config ${
        ./git-with-signing-key-id-ssh-expected.conf
      }
    '';
  };
}
