args@{flakeRoot, inputs, lib, config, pkgs, napslib, ...}:

/* Initializes the container with the first pull */
let

    domain = config.naps.topology.domain;
    HYDRA_URL = "hydra.${domain}";
    mkCDInit =
        env:
        {project, jobset, owner, mode,...}:
        let
            ctdir = "/var/lib/${napslib.envUID env}";
            stateDir = "${ctdir}/${project}";
        in ''
            set -euo pipefail

            URL="https://${HYDRA_URL}/jobset/${project}/${jobset}/latest-finished"
            HEADER="Accept: application/json"
            
            echo "Bootstrapping ${project}:${jobset}..."
            while [[ ! -L "${stateDir}/${jobset}" ]]; do
                NEW_PATH=$(${lib.getExe pkgs.curl} --cacert /etc/root_ca.crt -L -H "$HEADER" $URL | \
                             ${lib.getExe pkgs.jq} -r '.buildoutputs.out.path // empty')
                if [[ -n $NEW_PATH ]]; then
                    echo "Build found: installing..."
                    ${pkgs.nix}/bin/nix-store --realise "$NEW_PATH" --add-root "${stateDir}/${jobset}.gcroot" --indirect
                    ln -sfn "$NEW_PATH" "${stateDir}/${jobset}"
                    echo "$NEW_PATH" > "${ctdir}/path.txt"
                    break
                else
                    sleep 10
                fi
            done

        '';

    refreshCD = 
        env:
        {project, jobset, owner, mode, reload, ...}:
        let
            ctdir = "/var/lib/${napslib.envUID env}";
            stateDir = "${ctdir}/${project}";

        in 
        ''
                URL="https://${HYDRA_URL}/jobset/${project}/${jobset}/latest-finished"
                HEADER="Accept: application/json"

                OLD_PATH=$(cat ${ctdir}/path.txt)

                NEW_PATH=$(${lib.getExe pkgs.curl} --cacert /etc/root_ca.crt -L -H "$HEADER" $URL | \
                             ${lib.getExe pkgs.jq} -r '.buildoutputs.out.path // empty')
                if [[ "$NEW_PATH" != "$OLD_PATH" ]]; then
                    echo "Build found: installing..."
                    ${pkgs.nix}/bin/nix-store --realise "$NEW_PATH" --add-root "${stateDir}/${jobset}.tmp" --indirect
                    mv -T "${stateDir}/${jobset}.tmp" "${stateDir}/${jobset}"
                    echo "$NEW_PATH" > "${ctdir}/path.txt"
                    ${lib.getExe pkgs.nixos-container} run ${napslib.envUID env}  -- systemctl restart ${lib.concatStringsSep " " reload}
                else
                    sleep 10
                fi
         '';


in {
    inherit mkCDInit refreshCD;
}
