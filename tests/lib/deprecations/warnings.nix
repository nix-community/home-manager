{ lib, pkgs, ... }:

{
  nmt.script =
    let
      expected = pkgs.writeText "deprecation-warnings.expected" ''
        Using `programs.example.settings` as a list is deprecated and will be
        removed in a future release. Please use `programs.example.settings.items` instead.

        Move list entries under `settings.items`.

        The value "kde6" for `qt.platformTheme.name` is deprecated and will be
        removed in a future release. Please use "kde" instead.
      '';

      actual = pkgs.writeText "deprecation-warnings.actual" (
        lib.hm.deprecations.mkDeprecatedOptionValueWarning {
          option = [
            "programs"
            "example"
            "settings"
          ];
          old = "a list";
          replacement = "`programs.example.settings.items`";
          details = "Move list entries under `settings.items`.";
        }
        + "\n"
        + lib.hm.deprecations.mkDeprecatedOptionValueRenameWarning {
          option = [
            "qt"
            "platformTheme"
            "name"
          ];
          old = ''"kde6"'';
          replacement = ''"kde"'';
        }
      );
    in
    ''
      assertFileContent ${actual} ${expected}
    '';
}
