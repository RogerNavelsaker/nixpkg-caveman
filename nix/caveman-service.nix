{ pkgs, system }:

let
  version = "bin-v2.1.0";
  assets = {
    x86_64-linux = {
      proxy = {
        file = "caveman-proxy_linux_amd64";
        hash = "sha256-RENtaXBa2ZaFY8GBzRHTltauXuzNjb8ij2Il2S363LE=";
      };
      mcp = {
        file = "caveman-mcp_linux_amd64";
        hash = "sha256-JDOeZF2mb7NYDj2UEHQ0mYRXSCOPAdDcgJczD8sPm94=";
      };
    };
    aarch64-linux = {
      proxy = {
        file = "caveman-proxy_linux_arm64";
        hash = "sha256-WogZeZNNUYIsz56hPFGXaf6hjFLAYeFOa9DZ+VDOdg8=";
      };
      mcp = {
        file = "caveman-mcp_linux_arm64";
        hash = "sha256-+0m5lu7lopemdKBnl5kx2aKNWcvnNb4rkQTnUZ73BCo=";
      };
    };
  };
  selected = assets.${system} or (throw "Caveman service binaries do not support ${system}");
  fetchAsset =
    { file, hash }:
    pkgs.fetchurl {
      url = "https://github.com/JuliusBrussee/caveman/releases/download/${version}/${file}";
      inherit hash;
    };
  proxy = fetchAsset selected.proxy;
  mcp = fetchAsset selected.mcp;
in
{
  inherit version;
  package = pkgs.runCommand "caveman-service-${version}" { } ''
    mkdir -p "$out/bin"
    install -m 0555 ${proxy} "$out/bin/caveman-proxy"
    install -m 0555 ${mcp} "$out/bin/caveman-mcp"
  '';
}
