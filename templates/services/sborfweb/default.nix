{flakeRoot, lib, inputs, path, config, infra,  beds, ...}:
let

    cd = beds.sborfweb;
    sborf = "/var/lib/sborfweb/${cd.project}/${cd.jobset}";
    path = "${sborf}/bin/sborfweb";

in {

networking.firewall.allowedTCPPorts = [8080]; #NEEDED ??? TODO
systemd.services.sborfweb = {
    description = "Sborf"; #TODO
    after = ["network.target"];
    wantedBy = ["multi-user.target"];

    script = ''
        exec ${path} 
    '';

    serviceConfig = {
        Type = "simple";
        Restart = "always";
        RestartSec = "5s";
        StateDirectory = "sborfweb";
        DynamicUser = false;
        User = "sborfweb";
    };

    environment = {
        PORT="8080";
    };
};

}
