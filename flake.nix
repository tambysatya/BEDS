{
description = "Automatic generation of Terraform and NixOS configurations for a small research lab";
	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
        naps = {
            url = "github:tambysatya/naps?ref=refactor-secrets";
            inputs.nixpkgs.follows = "nixpkgs";
        };
	};

  outputs = inputs@{nixpkgs, self, naps,
                    ...}:
    let system ="x86_64-linux";
        lib = nixpkgs.lib;
        pkgs = nixpkgs.legacyPackages.${system};


        mkArgs = 
            args@{extraArgs, modules, view ? config: {}}:
            let view' = config: view config // {beds = config.beds;};
                extraArgs' = extraArgs // {napslib = naps.lib.utils;};
                modules' = modules ++ [ ./modules/beds ];
            in {view=view'; extraArgs=extraArgs'; modules=modules';};
            


        compileModule = 
            args@{extraArgs, modules, view ? config: {}}:
            naps.lib.compileModule (mkArgs args);

        compileConfig = args: (compileModule args).config;
        compileBEDS = args: (compileConfig args).beds;
        compileNAPS = args: (compileConfig args).naps;
        compileNixos = 
            args:
            let args' = mkArgs args;
            in naps.lib.compileNixos args' // {iso = naps.lib.compileIso args';};

        exposeApps = args: naps.lib.exposeApps (mkArgs args);


    in {
        lib = {
           inherit exposeApps compileNixos compileNAPS compileBEDS;
           inherit (naps.lib) compileTerranix gen-config-checks;

        };
        hydraJobs = {
            inherit (self) checks;
        };
        templates.default = {
            path = ./templates;
            description = "Scheme of configuration";
        };
  };
}


