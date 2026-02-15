{
  lib,
  stdenv,
  zig,
  pkg-config,
  xorg,
  lua5_4,
  freetype,
  fontconfig,
  gitRev ? "unknown",
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "oxwm";
  version = "${lib.substring 0 8 gitRev}";

  src = ./.;

  nativeBuildInputs = [zig.hook pkg-config];

  buildInputs = [
    xorg.libX11
    xorg.libXinerama
    xorg.libXft
    lua5_4
    freetype
    fontconfig
  ];

  postInstall = ''
    install resources/oxwm.desktop -Dt $out/share/xsessions
    install -Dm644 resources/oxwm.1 -t $out/share/man/man1
    install -Dm644 templates/oxwm.lua -t $out/share/oxwm
  '';

  # tests require a running X server
  doCheck = false;

  passthru.providedSessions = ["oxwm"];

  meta = {
    description = "Dynamic window manager written in Zig, inspired by dwm";
    homepage = "https://github.com/tonybanters/oxwm";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
    mainProgram = "oxwm";
  };
})
