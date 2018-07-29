{ stdenv, fetchurl, cmake, libGLU_combined, wxGTK, zlib, libX11, gettext, glew, cairo, curl, openssl, boost, pkgconfig, doxygen, glm, libngspice, opencascade, swig, python27Packages }:

stdenv.mkDerivation rec {
  name = "kicad-${version}";
  series = "5.0";
  version = "5.0.0";

  srcs = [
    (fetchurl {
      url = "https://code.launchpad.net/kicad/${series}/${version}/+download/kicad-${version}.tar.xz";
      sha256 = "17nqjszyvd25wi6550j981whlnb1wxzmlanljdjihiki53j84x9p";
    })

    (fetchurl {
      url = "https://github.com/KiCad/kicad-symbols/archive/${version}.tar.gz";
      sha256 = "09d8rmzssb0qfiicsh2wjg4yb5jjcb1nj2ib9ks8qhysm3zk3y8b";
    })

    (fetchurl {
      url = "https://github.com/KiCad/kicad-footprints/archive/${version}.tar.gz";
      sha256 = "19p20j8kgajmq8idy5wcxlx6x5h73aswkrd55b87avmn8c827h16";
    })

    (fetchurl {
      url = "https://github.com/KiCad/kicad-packages3D/archive/${version}.tar.gz";
      sha256 = "0nfn4353hp7qyim5q08djm422aibx703h92b8ycwc7kfi3xhv6wf";
    })
  ];

  sourceRoot = "kicad-${version}";

  cmakeFlags = ''
    -DKICAD_SKIP_BOOST=ON
    -DKICAD_BUILD_VERSION=${version}
    -DKICAD_REPO_NAME=stable
    -DCMAKE_CXX_FLAGS=-I${python27Packages.wxPython}/include/wx-3.0
  '';

  enableParallelBuilding = true; # often fails on Hydra: fatal error: pcb_plot_params_lexer.h: No such file or directory

  nativeBuildInputs = [ pkgconfig ];
  buildInputs = [ cmake libGLU_combined wxGTK zlib libX11 gettext glew cairo curl openssl boost doxygen glm libngspice opencascade swig python27Packages.python python27Packages.wxPython ];

  # They say they only support installs to /usr or /usr/local,
  # so we have to handle this.
  patchPhase = ''
    sed -i -e 's,/usr/local/kicad,'$out,g common/gestfich.cpp
  '';

  postUnpack = ''
    pushd $(pwd)
  '';

  postInstall = ''
    popd

    pushd kicad-library-*
    cmake -DCMAKE_INSTALL_PREFIX=$out
    make $MAKE_FLAGS
    make install
    popd

    pushd kicad-footprints-*
    mkdir -p $out/share/kicad/modules
    cp -R *.pretty $out/share/kicad/modules/
    popd
  '';


  meta = {
    description = "Free Software EDA Suite";
    homepage = http://www.kicad-pcb.org/;
    license = stdenv.lib.licenses.gpl2;
    maintainers = with stdenv.lib.maintainers; [viric];
    platforms = with stdenv.lib.platforms; linux;
    hydraPlatforms = []; # 'output limit exceeded' error on hydra
  };
}
