{
description = "Automatic generation of Terraform and NixOS configurations for a small research lab";
	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
        naps = {
            url = "github:tambysatya/naps";
            inputs.nixpkgs.follows = "nixpkgs";
        };
	};

  outputs = inputs@{nixpkgs, self, naps,
                    ...}:
    let system ="x86_64-linux";
        lib = nixpkgs.lib;
        pkgs = nixpkgs.legacyPackages.${system};

        compileBEDS = args: (naps.lib.compileModule args).config.beds;
        compileNixos = 
            args@{extraArgs, modules, view ? config: {}}:
            let view' = config: view config // {beds = config.beds;};
                extraArgs' = extraArgs // {napslib = naps.lib.utils;};
                modules' = modules ++ [ ./modules/beds ];
                args' = {view=view'; extraArgs=extraArgs'; modules=modules';};
            in naps.lib.compileNixos args' // {iso = naps.lib.compileIso args';};

    in {
        lib = {
           inherit compileNixos compileBEDS;
           inherit (naps.lib) exposeApps gen-config-checks compileNAPS compileModule compileTerranix;

        };
        hydraJobs = {
            inherit (self) checks;
        };

        checks.${system} = {
            template = 
                let flake = import ./templates/flake.nix;
                    outputs = flake.outputs {self=flake; inherit nixpkgs naps; beds=self;};
                in
                builtins.seq outputs (pkgs.runCommand 
                    "test-template-default" 
                    { }
                    ''
                        echo "Template test success";
                        touch $out
                    '');
        };
        templates.default = {
            path = ./templates;
            description = "Scheme of configuration";
        };
  };
}


