{
  description = "Nix packages and OCI image for Caveman";

  nixConfig = {
    extra-substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      "https://rogernavelsaker.cachix.org"
      "https://nacosolutions.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "rogernavelsaker.cachix.org-1:n1DtzMNhA9Rz4Kg3xlXOi/KceULu8VrMbs9WXyMFQNQ="
      "nacosolutions.cachix.org-1:JzCiW2CLcuLXtwOVAg3SlSK/kpqWbfSFEVenyKVUlug="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        lib = pkgs.lib;
        service = import ./nix/caveman-service.nix { inherit pkgs system; };
        cavemanService = service.package;
        cavemanCli = pkgs.callPackage ./nix/caveman-cli.nix { };

        image = pkgs.dockerTools.buildLayeredImage {
          name = "agent-services-caveman";
          tag = "latest";
          maxLayers = 16;
          contents = [
            pkgs.cacert
            pkgs.tzdata
            pkgs.dockerTools.fakeNss
            cavemanService
          ];
          fakeRootCommands = ''
            mkdir -p ./tmp ./data
            chown -R 10001:10001 ./data
            chmod 0700 ./data
            chmod 1777 ./tmp
          '';
          config = {
            Labels = {
              "org.opencontainers.image.title" = "Caveman Proxy";
              "org.opencontainers.image.description" =
                "Caveman proxy and MCP binaries with a shared persistent recovery store";
              "org.opencontainers.image.source" = "https://github.com/RogerNavelsaker/nixpkg-caveman";
              "org.opencontainers.image.version" = service.version;
              "org.opencontainers.image.revision" =
                if self ? dirtyRev then self.dirtyRev else self.rev or "unknown";
            };
            User = "10001:10001";
            Entrypoint = [ "${cavemanService}/bin/caveman-proxy" ];
            Env = [
              "PATH=${lib.makeBinPath [ cavemanService ]}"
              "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
              "HOME=/data"
              "TMPDIR=/tmp"
              "TZ=UTC"
              "CAVEMAN_HOME=/data"
              "CAVEMAN_CCR_DB=/data/ccr.db"
              "CAVEMAN_LISTEN=0.0.0.0:8787"
            ];
            WorkingDir = "/data";
            Volumes = {
              "/data" = { };
            };
            ExposedPorts = {
              "8787/tcp" = { };
            };
          };
        };
      in
      {
        packages = {
          default = cavemanService;
          caveman = cavemanService;
          caveman-service = cavemanService;
          caveman-image = image;
        }
        // lib.optionalAttrs (system == "x86_64-linux") {
          caveman-cli = cavemanCli;
        };

        checks = {
          caveman-image = image;
        }
        // lib.optionalAttrs (system == "x86_64-linux") {
          caveman-cli = cavemanCli;
        };
      }
    );
}
