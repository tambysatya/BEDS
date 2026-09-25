{path, ...}:
{

  /* Standard NAPS declaration */

  config.naps.topology = {
    provisionerHost = "provisioner.local";
    provisionerAddr = "192.168.1.100";
    domain = "local";
    vmSubnet = "192.168.1.0/24";
    dns = ["8.8.8.8" "8.8.4.4"];
    gateway = "192.168.1.1";
    rootSSHPublicKeys = [
        # Enter your ssh keys here
    ];
    services = {
        "sborf-main".is = "sborfweb"; # deployement example

        "stepca-main".is = "step-ca"; # TLS certification authority: mandatory in NAPS
        "hydra-main".is = "hydra"; # The building server: mandatory in BEDS
        "pg-main".is = "postgres"; # centralized database for Hydra
        "logs-main".is = "journald-remote"; # centralized logging: recommended
    };
    hosts = {
      cpuhost1 = {
        ipAddress = "192.168.2.10";
      };
    };

    vms = {
      identity = {
        host = "cpuhost1";
        vcpu = 4;
        memory = 8000;
        ip = "192.168.1.200";
        services = ["stepca-main"];
        disks = [
            {type="disk"; path="/dev/pvhdd/ldap"; mount="/var/lib/openldap/data"; fs="xfs";}
        ];

      };
      postgres = {
        host = "cpuhost1";
        vcpu = 4;
        memory = 8000;
        disks = [
            {type="disk"; path="/dev/ssd/postgres"; mount="/var/lib/postgresql"; fs="xfs"; options=["nofail"];}
        ];

        ip = "192.168.1.202";
        services = ["pg-main"]; 
      };
      build  = {
        host = "cpuhost1";
        vcpu = 8;
        memory = 8000;

        ip = "192.168.1.204";
        services = ["hydra-main"]; 
        disks = [
            {type="disk"; path="/dev/ssd/hydra"; mount="/nix"; fs="xfs"; options=["noatime"];}
            {type="disk"; path="/dev/pvhdd/hydraCache"; mount="/var/lib/hydra/cache"; fs="xfs"; options=["noatime"];}
        ];

      };
      logs = {
        host = "cpuhost1";
        vcpu = 2;
        memory = 4096;

        ip = "192.168.1.205";
        services = ["logs-main"]; 
        disks = [
            {type="disk"; path="/dev/pvhdd/logs"; mount="/var/log/journal/remote"; fs="ext4"; options=["noatime"];}
        ];

      };
      cd = {
        host = "cpuhost1";
        vcpu = 8;
        memory = 8000;
        ip = "192.168.1.200";
        containers = ["sborf-main"]; 
      };
    };
  };

}

