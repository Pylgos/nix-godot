{ cell, inputs }:

let
  nixpkgs = inputs.nixpkgs;
  l = nixpkgs.lib // builtins;
  inherit (cell.lib) buildGodot4;
in
{
  godot-master = buildGodot4 { src = inputs.godot-master-source; };
  godot-master-debug = buildGodot4 { src = inputs.godot-master-source; production = false; debugSymbols = true; };
}