{ cell, inputs }:

let
  nixpkgs = inputs.nixpkgs;
  l = nixpkgs.lib // builtins;
  inherit (cell.lib) buildGodot4;
in
{
  godot-master = buildGodot4 { src = inputs.godot-master-source; };

  test-extension = nixpkgs.stdenv.mkDerivation {
    name = "test-extension";
    src = inputs.self + /test;
    cmakeFlags = [ "-GNinja" ];
    nativeBuildInputs = [ nixpkgs.cmake nixpkgs.ninja ];
    buildInputs = [ cell.packages.godot-master.godot-cpp ];
    preConfigure = ''
      env
    '';
  };
}