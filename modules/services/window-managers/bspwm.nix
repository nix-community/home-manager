{ config, lib, pkgs, ... }:

with lib;

let

	cfg = config.xsession.windowManager.bspwm;
	bspwm = cfg.package;

	formatConfig = n: v:
    let
      formatList = x:
        if isList x
        then throw "can not convert 2-dimensional lists to bspwm format"
        else formatValue x;

      formatValue = v:
        if isBool v then (if v then "true" else "false")
        else if isList v then concatMapStringsSep ", " formatList v
        else toString v;
    in
      "bspc config ${n} ${formatValue v}";

	formatStartupPrograms = n:
		map(s: s + " &") n;
in

{
  options = {
	xsession.windowManager.bspwm = {
		enable = mkEnableOption "bspwm window manager."; 

		package = mkOption {
				type = types.package;
				default = pkgs.bspwm;
				defaultText = "pkgs.bspwm";
				example = "pkgs.bspwm-unstable";
				description = ''
					bspwm package to use.
				'';
		};

		config = mkOption {
			type = types.nullOr types.attrs;
			default = null;
			description = "bspwm configuration";
			example = {
				"border_width" = 2;
				"split_ratio" = 0.52;
				"gapless_monocle" = true;
			};
		};

		extraConfig = mkOption {
			type = types.lines;
			default = "";
			description = "Additional configuration to add";
			example = ''
				bspc rule -a Gimp desktop='^8' state=floating follow=on
				bspc rule -a Chromium desktop='^2'
				bspc rule -a mplayer2 state=floating
				bspc rule -a Kupfer.py focus=on
				bspc rule -a Screenkey manage=off
			'';
		};

		startupPrograms = mkOption {
			type = types.listOf types.string;
			default = [];
			description = "Programs that are going to be executed in the startup";
			example = ''
				[
					"numlockx on"
					"tilda"
				]
			'';
		};
	};
  };

	config = mkIf cfg.enable (mkMerge [
		{
			home.packages = [ bspwm ];
			xsession.windowManager.command = "${cfg.package}/bin/bspwm";
		}

		(mkIf (cfg.config != null) {
			xdg.configFile."bspwm/bspwmrc" = {
				executable = true;
				text = "#!/bin/sh\n\n" + 
				concatStringsSep "\n" ([]
					++ (optionals (cfg.config != null) (mapAttrsToList formatConfig cfg.config))
					++ [ "" ]
					++ (optional (cfg.extraConfig != "") cfg.extraConfig)
					++ (optionals (cfg.startupPrograms != null) (formatStartupPrograms cfg.startupPrograms))
				) + "\n";
			};
		})
	]);
}
