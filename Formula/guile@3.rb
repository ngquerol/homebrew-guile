class GuileAT3 < Formula
  desc "GNU Ubiquitous Intelligent Language for Extensions — version 3"
  homepage "https://www.gnu.org/software/guile/"
  url "https://ftp.gnu.org/gnu/guile/guile-3.0.2.tar.xz"
  sha256 "53c47d320533c80a3145adbd83e14bbe107c0441c18a8b214ff20849b28a9f8a"

  bottle do
    root_url "https://dl.bintray.com/ngqrl/bottles-guile"
    sha256 "0dcd989c3a02df906506f202b475b7f258c23f1a206e7ca75e0e6ddc575041c3" => :catalina
  end

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

    system "./configure",
           "--disable-dependency-tracking",
           "--prefix=#{prefix}",
           "--program-suffix=-3.0",
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

    # Install GDB support files
    (share/"gdb/auto-load").install Dir["#{lib}/*-gdb.scm"]

    # Prevent conflicts with other versions of Guile
    Pathname
      .glob(format("{%<dirs>s}/*",
                   :dirs => ["aclocal", "info"] .map { |dir| share/dir } .join(",")))
      .each do |file|
      mv(file, format("%<directory>s/%<basename>s%<suffix>s%<extension>s",
                     :directory => File.dirname(file),
                     :basename  => File.basename(file, ".*"),
                     :suffix    => "-3.0",
                     :extension => File.extname(file)))
    end
  end

  test do
    test_file = (testpath/"hello.scm")

    test_file.write <<~EOS
      (display "Hello World")
      (newline)
    EOS

    ENV["GUILE_AUTO_COMPILE"] = "0"

    output = shell_output("#{bin}/guile-3.0 #{test_file}")
    assert_equal "Hello World", output.strip
  end
end
