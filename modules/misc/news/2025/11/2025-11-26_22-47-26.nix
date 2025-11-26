{
  time = "2025-11-26T21:47:26+00:00";
  condition = true;
  message = ''
    A new module `services.update-flake-inputs` is now available to automate
    Nix flake input updates safely. The process is as follows for each
    configured directory:

    1. Make sure that `flake.nix` is in a clean state in the Git repository,
       otherwise skip the directory.
    2. Make sure nothing is staged in the Git repository, otherwise skip the
       directory.
    3. Update a single input at a time. For each input:
       1. If the input is already up to date, skip the rest of the steps.
       2. Make sure all the NixOS configurations and dev shells still build
          after each update (optionally with extra commands).
       3. Commit `flake.lock` (and only `flake.lock`) if all the build and extra
          commands pass.
       4. Revert `flake.lock` if any of the above fails.
    4. Report errors about inputs which can't be updated after processing each
       directory.
  '';
}
