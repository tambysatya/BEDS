args@{flakeRoot, inputs, lib, config, ...}:
let
    cd-init = import ./cd-init.nix args;

    ret = cd-init;
in ret
