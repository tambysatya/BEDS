args@{flakeRoot, inputs, self, lib, config, napslib, path,...}:
let
    
    domain = config.naps.topology.domain;
    scripts = import ../../scripts args;
    HYDRA_URL = "hydra.${domain}";

    mkCDBootstrap =
        srvname: cd@{project, jobset, owner, mode, ...}: env: 
        {
            ${napslib.envHost env}.config = {
                systemd.services."cd-${srvname}-bootstrap" = {
                    wantedBy = ["multi-user.target"];
                    after = ["network-online.target"];
                    requires = ["network-online.target"];
                    before = ["containers@${napslib.envUID env}.service"];
                    requiredBy = ["containers@${napslib.envUID env}.service"];

                    serviceConfig = {
                        Type = "oneshot";
                        StateDirectory = srvname;
                        Restart = "on-failure";
                        RestartSec = "2s";
                        RemainAfterExit = false;
                    };

                    script = scripts.mkCDInit env cd;
                };
            };
        };
    mkBindMount =
        srvname: cd@{owner, project, jobset, mode, ...}: env:  
        let path = "/var/lib/${napslib.envUID env}";
        in
        {
            ${napslib.envHost env}.config = {
                containers.${napslib.envUID env}.bindMounts = {
                   "/var/lib/${jobset}" = {
                        hostPath = path;
                        isReadOnly = true;
                   };
                };
                systemd.tmpfiles.rules = [ #initialize the directory at boot time
                    "d ${path} 755 ${owner} ${owner}"
                ];
            };
        };
     mkCDRefresh =
        srvname: cd@{project, jobset, owner, mode, ...}: env: 
        {
            ${napslib.envHost env}.config = {
                systemd.services."cd-${srvname}" = {
                    description = "Continuous deployement of ${srvname}";
                    wantedBy = ["multi-user.target"];
                    after= ["cd-${srvname}-bootstrap.service"];
                    requires = ["cd-${srvname}-bootstrap.service"];

                    serviceConfig = {
                        Type = "oneshot";
                        StateDirectory = srvname;
                        Restart = "on-failure";
                        RestartSec = "2s";
                    };

                    script = scripts.refreshCD (napslib.envUID env) cd;
                };
                systemd.timers."cd-${srvname}" = {
                  wantedBy = [ "timers.target" ];
                  timerConfig = {
                    OnUnitInactiveSec = "60s"; # Every 60s AFTER the build succeed (because the build can last more than 60s)
                    AccuracySec = "1s";
                  };

                };

            };
        };       

    setSubstituer = 
        env: {
            ${napslib.envHost env}.config = {
                nix.settings = {
                    extra-substituters = [
                        "https://cache.${config.naps.topology.domain}"
                    ];
                    extra-trusted-public-keys = [
                        (builtins.readFile "${path}/.secrets/git/hydra-cache.pub")
                    ];
                };
            };
        };
    bedsServices = lib.filterAttrs (name: _: builtins.hasAttr name config.beds) config.naps.services;

    processDeployements =
        srvname: cd: env: 
        napslib.mergeAll  [
            (mkCDBootstrap srvname cd env)
            (mkBindMount srvname cd env)
            (mkCDRefresh srvname cd env)
            (setSubstituer env)
        ];
    processService = 
        srvname: {deployements,...}:
        map (processDeployements srvname config.beds.${srvname}) (builtins.attrValues deployements);

in {
    imports = [./options];
    config.naps.outputs.systems = napslib.mergeAll (lib.concatLists (lib.mapAttrsToList processService bedsServices));
}
