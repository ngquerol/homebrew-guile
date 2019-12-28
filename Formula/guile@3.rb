class GuileAT3 < Formula
  desc "GNU Ubiquitous Intelligent Language for Extensions — version 3 BETA"
  homepage "https://www.gnu.org/software/guile/"
  url "https://alpha.gnu.org/gnu/guile/guile-2.9.7.tar.gz"
  sha256 "280fc7cc6d48f15a5ef5ff9fa1ca6d42da0ac8153e68c7ac2d52e996fdd36af0"

  keg_only "m4 macros, texinfo & man pages conflicts with other installed versions of Guile"

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "gnu-sed" => :build

  depends_on "bdw-gc"
  depends_on "gettext"
  depends_on "gmp"
  depends_on "libffi"
  depends_on "libtool"
  depends_on "libunistring"
  depends_on "pkg-config" # guile-config is a wrapper around pkg-config.
  depends_on "readline"

  def install
    # Work around Xcode 11 clang bug
    # https://bitbucket.org/multicoreware/x265/issues/514/wrong-code-generated-on-macos-1015
    ENV.append_to_cflags "-fno-stack-check" if DevelopmentTools.clang_build_version >= 1010

    system "./configure", "--disable-dependency-tracking",
                          "--prefix=#{prefix}",
                          "--program-suffix=-#{version.to_s.slice(/\d\.\d/)}",
                          "--with-libreadline-prefix=#{Formula["readline"].opt_prefix}",
                          "--with-libgmp-prefix=#{Formula["gmp"].opt_prefix}"

    system "make", "install"

    # A really messed up workaround required on macOS --mkhl
    Pathname.glob("#{lib}/*.dylib") do |dylib|
      lib.install_symlink dylib.basename => "#{dylib.basename(".dylib")}.so"
    end

    # This is either a solid argument for guile including options for
    # --with-xyz-prefix= for libffi and bdw-gc or a solid argument for
    # Homebrew automatically removing Cellar paths from .pc files in favour
    # of opt_prefix usage everywhere.
    inreplace lib/"pkgconfig/guile-3.0.pc" do |s|
      s.gsub! Formula["bdw-gc"].prefix.realpath, Formula["bdw-gc"].opt_prefix
      s.gsub! Formula["libffi"].prefix.realpath, Formula["libffi"].opt_prefix
    end

    (share/"gdb/auto-load").install Dir["#{lib}/*-gdb.scm"]
  end

  test do
    hello = testpath/"hello.scm"
    hello.write <<~EOS
      (display "Hello World")
      (newline)
    EOS

    ENV["GUILE_AUTO_COMPILE"] = "0"

    system bin/"guile-#{version.to_s.slice(/\d\.\d/)}", hello
  end
end
