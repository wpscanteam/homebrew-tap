class Wpscan < Formula
  desc "Black box WordPress vulnerability scanner"
  homepage "https://wpscan.com/wordpress-security-scanner"
  url "https://github.com/wpscanteam/wpscan/archive/refs/tags/v4.2.0.tar.gz"
  sha256 "fa140b4ed31741da80d6e5f936a3a8c6cc87a0c6ebe093d87e1248cd7596257d"
  head "https://github.com/wpscanteam/wpscan.git", branch: "master"

  RUBY_FORMULA = "ruby@3.4".freeze

  depends_on "pkg-config" => :build
  depends_on "xz" => :build # nokogiri needs xzcat to extract its vendored libxml2
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
    # Persist the BUNDLE_WITHOUT that superenv sets, so `bundle exec` in bin/wpscan
    # does not look for the development and test gems that were never installed
    system bundle, "config", "set", "--local", "without", "development:test"
    system bundle, "install", "--jobs=#{ENV.make_jobs}"
    wpscan = Dir["#{libexec}/ruby/**/bin/wpscan"].last

    ruby_series = Formula[RUBY_FORMULA].version.to_s.split(".")[0..1].join(".")
    (bin/"wpscan").write <<~EOS
      #!/bin/bash
      GEM_HOME="#{libexec}/ruby/#{ruby_series}.0" BUNDLE_GEMFILE="#{libexec}/Gemfile" \\
        exec "#{formula_opt_bin(RUBY_FORMULA)}/ruby" "#{bundle}" exec \\
        "#{wpscan}" "$@"
    EOS
  end

  post_install_steps do
    # Update database
    run "wpscan", args: ["--update"], base: :bin
  end

  test do
    assert_match "URL: https://wordpress.org/",
                 pipe_output("#{bin}/wpscan --no-update --url https://wordpress.org/")
  end
end
