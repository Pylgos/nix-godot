{ inputs, cell }:
let
  inherit (inputs) cells;
in
{
  inherit (cells.godot.packages) godot-master godot-master-debug;
  inherit (cells.godot-cpp.packages) demo-extension;
}