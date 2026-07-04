{ lib, ... }:

{
  services.syncthing = {
    enable = true;
    settings.folders = {
      "Folder1" = {
        id = "ew8bc-4uanl";
        path = "/home/username/folder1";

        ignorePatterns = [
          "val1"
          "!val2"
          "*al3"
          "val'4"
          "val\"5"
        ];
      };
    };
  };

  nmt.script =
    let
      ignoreString = ''{"ignore":["val1","!val2","*al3","val'\'''4","val\"5"]}'';
      ignoreStringBad = ''{"ignore":["WRONG","!val2","*al3","val'\'''4","val\"5"]}'';
    in
    ''
      serviceFile=home-files/.config/systemd/user/syncthing-init.service
      assertFileExists "$serviceFile"
      assertFileExists home-files/.config/systemd/user/default.target.wants/syncthing-init.service
      assertFileContains "$serviceFile" "ExecStart="

      updateScript=$(grep -o '/nix/store/[^ ]*-merge-syncthing-config' "$TESTED/$serviceFile")
      assertFileContains "$updateScript" "/rest/db/ignores?folder=ew8bc-4uanl"
      assertFileContains "$updateScript" ${lib.escapeShellArg ignoreString}
      if grep -qF ${lib.escapeShellArg ignoreStringBad} "$(_abs "$updateScript")"; then
        fail "syncthing bad ignore string shouldn't be found in updateScript"
      fi
    '';
}
