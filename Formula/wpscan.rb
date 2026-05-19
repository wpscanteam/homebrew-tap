class Wpscan < Formula
  desc "Black box WordPress vulnerability scanner"
  homepage "https://wpscan.com/wordpress-security-scanner"
  url "https://github.com/wpscanteam/wpscan/archive/v4.0.0.tar.gz"
  sha256 "f69bebfa98cb6acdad53b0d4b1a4a06cf892e88c9207e0ac603628a2b326508f"
  head "https://github.com/wpscanteam/wpscan.git"

  RUBY_FORMULA = "ruby@3.4"

  depends_on "pkg-config" => :build
  depends_on RUBY_FORMULA

  uses_from_macos "curl"
  uses_from_macos "libffi", since: :catalina
  uses_from_macos "unzip"
  uses_from_macos "xz" # for liblxma
  uses_from_macos "zlib"

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

    ruby_series = Formula[RUBY_FORMULA].version.to_s.split(".")[0..1].join(".")
    (bin/"wpscan").write <<~EOS
      #!/bin/bash
      GEM_HOME="#{libexec}/ruby/#{ruby_series}.0" BUNDLE_GEMFILE="#{libexec}/Gemfile" \\
        exec "#{Formula[RUBY_FORMULA].opt_bin}/ruby" "#{bundle}" exec \\
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
