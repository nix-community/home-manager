{ config, pkgs, ... }:
{
  imports = [ ../../accounts/email-test-accounts.nix ];

  home.enableNixpkgsReleaseCheck = false;

  accounts.email.accounts."hm@example.com" = {
    maildir.path = "hm-example.com";
    neverest.enable = true;
  };

  programs.neverest = {
    package = config.lib.test.mkStubPackage {
      name = "neverest";
      outPath = "@neverest@";
    };
  };

  services.neverest = {
    enable = true;
    frequency = "hourly";
    preExec = ''
      echo "pre-exec 1"
      echo "pre-exec 2"
    '';
    postExec = ''
      echo "post-exec 1"
    '';
  };

  nmt.script =
    let
      serviceFile =
        if pkgs.stdenv.hostPlatform.isLinux then
          "home-files/.config/systemd/user/neverest.service"
        else
          "LaunchAgents/org.nix-community.home.neverest.plist";
    in
    ''
      assertFileExists "${serviceFile}"

      # Follow ExecStart to the generated sync script and verify it actually
      # carries the pre/post hooks and a per-account sync invocation — the
      # service-file tests only cover the unit wiring, not the script body.
      # nmt's asserts resolve relative paths against $TESTED; raw grep does not.
      script=$(grep -hoE '/nix/store/[a-z0-9]+-neverest-sync' "$TESTED/${serviceFile}" | head -n1)
      assertFileExists "$script"
      assertFileRegex "$script" 'pre-exec 1'
      assertFileRegex "$script" 'pre-exec 2'
      assertFileRegex "$script" 'neverest -c .* sync hm@example\.com'
      assertFileRegex "$script" 'post-exec 1'
    '';
}
