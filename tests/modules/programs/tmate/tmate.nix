{
  programs.tmate = {
    enable = true;
    port = 222;
    dsaFingerprint = "SHA256:1111111111111111111111111111111111111111111";
    extraConfig = ''set tmate-session-name "session-name"'';
  };

  nmt.script = let
    expectedConfig = ''
      set -g tmate-server-port 222
      set -g tmate-server-ed25519-fingerprint "SHA256:1111111111111111111111111111111111111111111"
      set tmate-session-name "session-name"
    '';
  in ''
    assertFileExists home-files/.tmate.conf
    assertFileContent home-files/.tmate.conf ${
      builtins.toFile "config" expectedConfig
    }
  '';
}
