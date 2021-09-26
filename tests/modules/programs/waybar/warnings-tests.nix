{ config, pkgs, lib, ... }:

with lib;

{
  config = {
    programs.waybar = {
      package = config.lib.test.mkStubPackage { outPath = "@waybar@"; };
      enable = true;
      settings = [{
        modules-left = [ "custom/my-module" ];
        modules-center =
          [ "this_module_is_not_a_valid_default_module_nor_custom_module" ];
        modules-right = [
          "battery#bat1" # CSS identifier is allowed
          "custom/this_custom_module_doesn't_have_a_definition_in_modules"
        ];

        modules = {
          "custom/this_module_is_not_referenced" = { };
          "battery#bat1" = { };
          "custom/my-module" = { };
        };
      }];
    };

    test.asserts.warnings.expected = [
      "The module 'this_module_is_not_a_valid_default_module_nor_custom_module' defined in 'programs.waybar.settings.[].modules-center' is neither a default module or a custom module declared in 'programs.waybar.settings.[].modules'"

      "The module 'custom/this_custom_module_doesn't_have_a_definition_in_modules' defined in 'programs.waybar.settings.[].modules-right' is neither a default module or a custom module declared in 'programs.waybar.settings.[].modules'"

      "The module 'custom/this_module_is_not_referenced' defined in 'programs.waybar.settings.[].modules' is not referenced in either `modules-left`, `modules-center` or `modules-right` of Waybar's options"
    ];

    nmt.script = ''
      assertPathNotExists home-files/.config/waybar/style.css
      assertFileContent \
        home-files/.config/waybar/config \
        ${
          pkgs.writeText "expected-json" ''
            [
              {
                "battery#bat1": {},
                "custom/my-module": {},
                "custom/this_module_is_not_referenced": {},
                "modules-center": [
                  "this_module_is_not_a_valid_default_module_nor_custom_module"
                ],
                "modules-left": [
                  "custom/my-module"
                ],
                "modules-right": [
                  "battery#bat1",
                  "custom/this_custom_module_doesn't_have_a_definition_in_modules"
                ]
              }
            ]
          ''
        }
    '';
  };
}
