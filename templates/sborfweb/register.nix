{flakeRoot, inputs, lib, config,...}:

let
    domain = config.naps.topology.domain;
in {
config.naps.services.sborfweb = {
    path = ./.;
    users.sborfweb = {service="sborfweb"; uid=50001;};
    endpoints.http = [{
       hostname = "sborfweb.${domain}"; 
       port = 8080;
       tls = true;
    }];
};
config.beds.sborfweb = {
    project = "team5";
    jobset = "sborfweb";
    owner = "sborfweb";
    mode = "0400";
    reload = ["sborfweb.service"];
};
}
