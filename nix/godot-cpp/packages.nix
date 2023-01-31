{ inputs, cell }:
let
  inherit (inputs) std nixpkgs;
in
{
  godot-master-test-extension = nixpkgs.stdenv.mkDerivation {
    name = "test-extension";
    src =
      let
        root = inputs.self + /test/godot-cpp-test;
      in
      std.incl root [
        (root + "/demo")
        (root + "/src")
        (root + "/CMakeLists.txt")
        (root + "/example.gdextension.in")
      ];
    cmakeFlags = [ "-GNinja" ];
    nativeBuildInputs = [ nixpkgs.cmake nixpkgs.ninja ];
    buildInputs = [ inputs.cells.godot.packages.godot-master.godot-cpp ];
  };
}
