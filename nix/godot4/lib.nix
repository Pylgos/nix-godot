{ inputs, cell }:

let
  nixpkgs = inputs.nixpkgs;
  l = nixpkgs.lib // builtins;

  buildGodot4 =
    { source
    , withPulseaudio ? false
    , withDbus ? true
    , withSpeechd ? false
    , withFontconfig ? true
    , withUdev ? true
    , withTouch ? true
    }:
    let
      options = {
        pulseaudio = withPulseaudio;
        dbus = withDbus; # Use D-Bus to handle screensaver and portal desktop settings
        speechd = withSpeechd; # Use Speech Dispatcher for Text-to-Speech support
        fontconfig = withFontconfig; # Use fontconfig for system fonts support
        udev = withUdev; # Use udev for gamepad connection callbacks
        touch = withTouch; # Enable touch events
      };
    in
    nixpkgs.stdenv.mkDerivation rec {
      pname = "godot";
      version = parseVersion source;
      src = source;

      nativeBuildInputs = with nixpkgs; [
        pkg-config
        autoPatchelfHook
        installShellFiles
      ];

      buildInputs = with nixpkgs; [
        scons
      ]
      ++ runtimeDependencies
      # Necessary to make godot see fontconfig.lib and dbus.lib
      ++ l.optional withFontconfig fontconfig
      ++ l.optional withDbus dbus;

      runtimeDependencies = with nixpkgs; [
        vulkan-loader
        alsa-lib
        xorg.libX11
        xorg.libXcursor
        xorg.libXinerama
        xorg.libXi
        xorg.libXrandr
        xorg.libXext
        xorg.libXfixes
        libGLU
      ]
      ++ l.optional withPulseaudio libpulseaudio
      ++ l.optional withDbus dbus.lib
      ++ l.optional withSpeechd speechd
      ++ l.optional withFontconfig fontconfig.lib
      ++ l.optional withUdev udev;


      postPatch = ''
        substituteInPlace ./platform/linuxbsd/detect.py \
          --replace '        env.ParseConfig("pkg-config xi --cflags")' \
                    '        env.ParseConfig("pkg-config xi --cflags")${"\n"}        env.ParseConfig("pkg-config xfixes --cflags")' \
          --replace '--cflags"' '--cflags --libs"'
      '';

      enableParallelBuilding = true;

      sconsFlags = "platform=linuxbsd target=editor production=true";
      preConfigure = ''
        sconsFlags+=" ${
          l.concatStringsSep " "
          (l.mapAttrsToList (k: v: "${k}=${l.toJSON v}") options)
        }"
      '';

      outputs = [ "out" "man" ];

      installPhase = ''
        mkdir -p "$out/bin"
        cp bin/godot.* $out/bin/godot
        installManPage misc/dist/linux/godot.6
        mkdir -p "$out"/share/{applications,icons/hicolor/scalable/apps}
        cp misc/dist/linux/org.godotengine.Godot.desktop "$out/share/applications/"
        substituteInPlace "$out/share/applications/org.godotengine.Godot.desktop" \
          --replace "Exec=godot" "Exec=$out/bin/godot"
        cp icon.svg "$out/share/icons/hicolor/scalable/apps/godot.svg"
        cp icon.png "$out/share/icons/godot.png"
      '';

      meta = with l; {
        homepage = "https://godotengine.org";
        description = "Free and Open Source 2D and 3D game engine";
        license = licenses.mit;
        platforms = [ "i686-linux" "x86_64-linux" ];
      };
    };

  parseVersion = source:
    let
      s = l.readFile (source + /version.py);
      f = t: l.elemAt (l.match ".+${t}[ ]*=[ ]*([^\n]+).+" s) 0;
      major = f "major";
      minor = f "minor";
      patch = f "patch";
      status = l.fromJSON (f "status");
    in
    "${major}.${minor}.${patch}-${status}";

in
{
  inherit buildGodot4;
}
