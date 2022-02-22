class Wpscan < Formula
  desc "Black box WordPress vulnerability scanner"
  homepage "https://wpscan.com/wordpress-security-scanner"
  url "https://github.com/wpscanteam/wpscan/archive/v3.8.21.tar.gz"
  sha256 "313354d66a58850bb2a6850e40e75eceb4bcd085bbfc792322a56d103d6aba26"
  head "https://github.com/wpscanteam/wpscan.git"

  depends_on "pkg-config" => :build
  depends_on "ruby"

  uses_from_macos "curl"
  uses_from_macos "unzip"
  uses_from_macos "xz" # for liblxma
  uses_from_macos "zlib"

  if MacOS.version < :catalina
    depends_on "libffi"
  else
    uses_from_macos "libffi"
  end

  def install
    inreplace "lib/wpscan.rb", /DB_DIR.*=.*$/, "DB_DIR = Pathname.new('#{var}/wpscan/db')"
    libexec.install Dir["*"]
    ENV["GEM_HOME"] = libexec
    ENV["BUNDLE_PATH"] = libexec
    ENV["BUNDLE_GEMFILE"] = libexec/"Gemfile"
    system "gem", "install", "bundler"
    bundle = Dir["#{libexec}/**/bundle"].last
    system bundle, "install", "--jobs=#{ENV.make_jobs}"
    wpscan = Dir["#{libexec}/ruby/**/bin/wpscan"].last

    ruby_series = Formula["ruby"].version.to_s.split(".")[0..1].join(".")
    (bin/"wpscan").write <<~EOS
      #!/bin/bash
      GEM_HOME="#{libexec}/ruby/#{ruby_series}.0" BUNDLE_GEMFILE="#{libexec}/Gemfile" \\
        exec "#{bundle}" exec "#{Formula["ruby"].opt_bin}/ruby" \\
        "#{wpscan}" "$@"
    EOS
  end

  def post_install
    # Update database
    system bin/"wpscan", "--update"
  end

  test do
    assert_match "URL: https://wordpress.org/",
                 pipe_output("#{bin}/wpscan --no-update --url https://wordpress.org/")
  end
end
