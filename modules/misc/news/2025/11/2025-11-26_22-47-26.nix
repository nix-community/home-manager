{
  time = "2025-11-26T21:47:26+00:00";
  condition = true;
  message = ''
    A new module `services.update-flake-inputs` is now available to automate
    Nix flake input updates safely. For each entry in
    `services.update-flake-inputs.directories`, this service will do the
    following:

    1. Check that there are no changes to `flake.lock`. Otherwise it
       will skip the directory and set exit code 80.
    2. Check that there are no staged changes to tracked files in the Git
       repository. Otherwise it will skip the directory and set exit code 81.
    3. If everything is clean, it will do the following for each flake input:
       1. Update the input. If this fails, it will revert `flake.lock`,
          set exit code 82, and skip the input.
       2. Check whether `flake.lock` was actually changed. If not, it
          will skip the input as there's nothing to do.
       3. Run `nix flake check` to make sure the update passes the
          built-in checks in the repository. If this fails, it will revert
          `flake.lock`, set exit code 83, and skip the input.

          If you want to run a stricter check than the basic one you can set
          `systemd.user.services.update-flake-inputs.Service.Environment = ["NIX_ABORT_ON_WARN=true"]`
          or add custom checks.
       4. Build the flake outputs:

          - NixOS configurations
          - Dev shells for the current architecture
          - Packages for the current architecture

          If any of them fail, it will revert `flake.lock`, set exit
          code 84, and skip the input.
       5. Run the Nix formatter. If this fails, it will revert
          `flake.lock`, set exit code 85, and skip the input.
       6. Commit `flake.lock`. If this fails, it will, you guessed it,
          revert `flake.lock`, set exit code 86, and skip the input.

    The script returns the last non-zero exit code, or zero if everything was
    successful.
  '';
}
