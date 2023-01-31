{ inputs, cell }:
let
  inherit (inputs) std nixpkgs;
in
{
  demo-extension = nixpkgs.callPackage
    { stdenv
    , cmake
    , ninja
    , godot-cpp ? inputs.cells.godot.packages.godot-master.godot-cpp
    }:
    nixpkgs.stdenv.mkDerivation {
    name = "test-extension";
    src =
      let
        root = inputs.self + /test/godot-cpp-test;
      in
      std.incl root [
        (root + "/src")
        (root + "/CMakeLists.txt")
        (root + "/example.gdextension.in")
      ];
    cmakeFlags = [ "-GNinja" ];
    nativeBuildInputs = [ cmake ninja ];
    buildInputs = [ godot-cpp ];
  };
}
