{flakeRoot, inputs, self, lib, config,...}:

let
    
    types = lib.types;
 
    continuousDeployement = types.submodule {
        options = {
            project = lib.mkOption {
                description = "Name of the project";
                type = types.str;
            };
            jobset = lib.mkOption {
                description = "Which jobset of the project";
                type = types.str;
            };
            reload = lib.mkOption {
                description = "Services to reload within the container";
                type = types.listOf types.str;
            };
            owner = lib.mkOption {
                description = "Service user";
                type = types.str;
            };
            mode = lib.mkOption {
                description = "Permissions";
                type = types.str;
                default = "0400";
            };
             
        };
    };

in {
options.beds = lib.mkOption {
    description = "Binaries and services to be continuously deployed";
    type = types.attrsOf continuousDeployement;
};
}
