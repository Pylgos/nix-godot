{ inputs, cell }:

let
  nixpkgs = inputs.nixpkgs;
  l = nixpkgs.lib // builtins;

  buildGodotHeaders = godot:
    let in
    nixpkgs.runCommand "godot-headers"
      {
        inherit godot;
      } ''
      mkdir -p "$out"
      cd "$out"
      HOME=/tmp "$godot/bin/godot" --dump-extension-api --dump-gdextension-interface --display-driver headless
    '';

  buildGodot4 =
    { src
    , precision ? "single"
    , target ? "editor"
    , buildCache ? null
    , doCache ? false
    , cacheLimit ? 5000
    , production ? true
    , withPulseaudio ? true
    , withDbus ? true
    , withSpeechd ? false
    , withFontconfig ? true
    , withUdev ? true
    , withTouch ? true
    , debugSymbols ? false
    } @ args:
    let
      options = {
        pulseaudio = withPulseaudio;
        dbus = withDbus; # Use D-Bus to handle screensaver and portal desktop settings
        speechd = withSpeechd; # Use Speech Dispatcher for Text-to-Speech support
        fontconfig = withFontconfig; # Use fontconfig for system fonts support
        udev = withUdev; # Use udev for gamepad connection callbacks
        touch = withTouch; # Enable touch events
        target = "editor";
        platform = "linuxbsd";
        production = if production then "true" else "false";
        precision = precision;
        debugSymbols = if debugSymbols then "true" else "false";
      };
      useCache = buildCache != null;

      self = (if debugSymbols then nixpkgs.stdenvAdapters.keepDebugInfo nixpkgs.stdenv else nixpkgs.stdenv).mkDerivation (rec {
        pname = "godot";
        version = parseVersion src;
        inherit src;

        dontStrip = debugSymbols;

        outputs = [ "out" "man" ] ++ l.optional doCache "buildCache";

        nativeBuildInputs = with nixpkgs; [
          pkg-config
          autoPatchelfHook
          installShellFiles
        ];

        buildInputs = with nixpkgs; [
          scons
        ];

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
          libxkbcommon
          libGL
        ]
        ++ l.optional withPulseaudio libpulseaudio
        ++ l.optional withDbus dbus
        ++ l.optional withDbus dbus.lib
        ++ l.optional withSpeechd speechd
        ++ l.optional withFontconfig fontconfig
        ++ l.optional withFontconfig fontconfig.lib
        ++ l.optional withUdev udev;

        enableParallelBuilding = true;

        sconsFlags = if (!doCache && useCache) then " --cache-readonly" else "";

        preConfigure = ''
          sconsFlags+=" ${
            l.concatStringsSep " "
            (l.mapAttrsToList (k: v: "${k}=${l.toJSON v}") options)
          }"
        '' + (
          if (doCache && useCache) then
            ''
              cp -a ${buildCache} $buildCache
              export SCONS_CACHE=$buildCache
              export SCONS_CACHE_LIMIT=${cacheLimit}
            ''
          else if (!doCache && useCache) then
            ''
              export SCONS_CACHE=${buildCache}
            ''
          else if (doCache && !useCache) then
            ''
              export SCONS_CACHE=$buildCache
              export SCONS_CACHE_LIMIT=${cacheLimit}
            ''
          else ""
        );

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

        passthru = rec {
          buildIncremental = newArgs:
            let
              cachedGodot = buildGodot4 (args // { doCache = true; });
            in
            buildGodot4 (newArgs // { buildCache = cachedGodot.buildCache; });

          godot-headers = buildGodotHeaders self;
          godot-cpp = inputs.cells.godot-cpp.lib.buildGodotCpp godot-headers;
          mkProject = mkProjectFor self;
        };

        meta = {
          homepage = "https://godotengine.org";
          description = "Free and Open Source 2D and 3D game engine";
          license = l.licenses.mit;
          platforms = [ "i686-linux" "x86_64-linux" ];
        };
      } // args);
    in
    self;

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

  mkProjectFor = godot:
    { nativeBuildInputs ? [ ]
    , preConfigure ? ""
    , addons ? [ ]
    , ...
    } @ args:
    let
      addons-paths = nixpkgs.buildEnv {
        name = "godot-nix-addons-path";
        paths = l.forEach addons (addon:
          nixpkgs.buildEnv {
            name = "${addon.name}-path";
            paths = [ addon ];
            extraPrefix = "/${addon.name}";
          }
        );
      };
    in
    nixpkgs.stdenv.mkDerivation (args // {
      nativeBuildInputs = nativeBuildInputs ++ [ godot ];

      preConfigure = ''
        ln -snf ${addons-paths} nix-addons
      '' + preConfigure;
    });

in
{
  inherit buildGodot4;
}
