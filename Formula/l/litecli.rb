class Litecli < Formula
  include Language::Python::Virtualenv

  desc "CLI for SQLite Databases with auto-completion and syntax highlighting"
  homepage "https://github.com/dbcli/litecli"
  url "https://files.pythonhosted.org/packages/f3/8e/2530fef1b2b63d4d59e89fea9d0bed8f204d1b7514e06b8be18c372a2be3/litecli-1.10.0.tar.gz"
  sha256 "ee9e2a93d193a555c0e661ed083943a6f932a9c8e8c267b689b469f9ac7a3e0c"
  license "BSD-3-Clause"

  bottle do
    rebuild 2
    sha256 cellar: :any_skip_relocation, arm64_sonoma:   "b9d8120a0c223ed04fc592f39991e1b0b4077b7a7f2e642ed2b41ad9a10b5acd"
    sha256 cellar: :any_skip_relocation, arm64_ventura:  "df4cd8db25541f000d2494b4c80ed9bc6c9ea4c7ca7703adfeed0052c04e1c80"
    sha256 cellar: :any_skip_relocation, arm64_monterey: "539beb394d90813f46c276d3a6f6bb5823c81abd2667d04914b25685fd4ba75c"
    sha256 cellar: :any_skip_relocation, sonoma:         "adead673456887368c5bae8ae51c891cdcf160121a4f1f39b5aedbf5b58bdf6e"
    sha256 cellar: :any_skip_relocation, ventura:        "c5c2e6be60117017aaef78a11b8f1019d3ebcadbcfe828738c8adee9fac34e38"
    sha256 cellar: :any_skip_relocation, monterey:       "5602bf3f603fe7eac404de507cc43fbc7992e1d820f63dbb974dfbaa3f747b15"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "09d5d857309e176624bc7f82b211b0529c13c26fac792d6cfec91ec2cf8c9fdc"
  end

  depends_on "pygments"
  depends_on "python-click"
  depends_on "python-tabulate"
  depends_on "python@3.12"
  depends_on "six"

  uses_from_macos "sqlite"

  resource "cli-helpers" do
    url "https://files.pythonhosted.org/packages/27/01/6aaa4fc415274ac77372b4d259c234b9f5bfc8d78144c3fda1f3019d4690/cli_helpers-2.3.0.tar.gz"
    sha256 "e7174d003a2b58fd3e31a73fbbc45d5aa513de62cbd42d437f78b9658bd5f967"
  end

  resource "configobj" do
    url "https://files.pythonhosted.org/packages/cb/87/17d4c6d634c044ab08b11c0cd2a8a136d103713d438f8792d7be2c5148fb/configobj-5.0.8.tar.gz"
    sha256 "6f704434a07dc4f4dc7c9a745172c1cad449feb548febd9f7fe362629c627a97"
  end

  resource "prompt-toolkit" do
    url "https://files.pythonhosted.org/packages/d9/7b/7d88d94427e1e179e0a62818e68335cf969af5ca38033c0ca02237ab6ee7/prompt_toolkit-3.0.41.tar.gz"
    sha256 "941367d97fc815548822aa26c2a269fdc4eb21e9ec05fc5d447cf09bad5d75f0"
  end

  resource "sqlparse" do
    url "https://files.pythonhosted.org/packages/65/16/10f170ec641ed852611b6c9441b23d10b5702ab5288371feab3d36de2574/sqlparse-0.4.4.tar.gz"
    sha256 "d446183e84b8349fa3061f0fe7f06ca94ba65b426946ffebe6e3e8295332420c"
  end

  resource "wcwidth" do
    url "https://files.pythonhosted.org/packages/2e/1c/21f2379555bba50b54e5a965d9274602fe2bada4778343d5385840f7ac34/wcwidth-0.2.10.tar.gz"
    sha256 "390c7454101092a6a5e43baad8f83de615463af459201709556b6e4b1c861f97"
  end

  def install
    virtualenv_install_with_resources
  end

  test do
    (testpath/".config/litecli/config").write <<~EOS
      [main]
      table_format = tsv
      less_chatty = True
    EOS

    (testpath/"test.sql").write <<~EOS
      CREATE TABLE IF NOT EXISTS package_manager (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name VARCHAR(256)
      );
      INSERT INTO
        package_manager (name)
      VALUES
        ('Homebrew');
    EOS
    system "sqlite3 test.db < test.sql"

    require "pty"
    output = ""
    PTY.spawn("#{bin}/litecli test.db") do |r, w, _pid|
      sleep 2
      w.puts "SELECT name FROM package_manager"
      w.puts "quit"

      begin
        r.each_line { |line| output += line }
      rescue Errno::EIO
        # GNU/Linux raises EIO when read is done on closed pty
      end
    end

    # remove ANSI colors
    output.gsub!(/\e\[([;\d]+)?m/, "")
    # normalize line endings
    output.gsub!(/\r\n/, "\n")

    expected = <<~EOS
      name
      Homebrew
      1 row in set
    EOS

    assert_match expected, output
  end
end
