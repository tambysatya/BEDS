{
description = "Automatic generation of Terraform and NixOS configurations for a small research lab";
	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
        beds = {
            url = "github:tambysatya/BEDS";
            inputs.nixpkgs.follows = "nixpkgs";
        };
	};

  outputs = inputs@{nixpkgs, self, beds,
                    ...}:
    let system ="x86_64-linux";
        lib = nixpkgs.lib;
        pkgs = nixpkgs.legacyPackages.${system};

        args = {
            extraArgs = {path = ./.;};
            modules = [
                ./example.nix # infrastructure
                ./services/sborfweb/register.nix # custom app
            ];
        };
    in  beds.lib.exposeApps args // {
        hydraJobs = {
            inherit (self) checks;
        };
        nixosConfigurations = beds.lib.compileNixos args;
        terranix = beds.lib.compileTerranix args;

        checks.${system} = beds.lib.gen-config-checks inputs;
  };
}


