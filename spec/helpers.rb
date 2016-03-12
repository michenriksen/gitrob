module Helpers
  def capture_stdout(&block)
    original_stdout = $stdout
    original_stderr = $stderr
    $stdout = fakestdout = StringIO.new
    $stderr = StringIO.new
    begin
      yield block
    ensure
      $stdout = original_stdout
      $stderr = original_stderr
    end
    fakestdout.string
  end

  def read_fixture(file_name)
    JSON.parse(File.open(
      File.dirname(__FILE__) + "/support/fixtures/" + file_name, "rb"
    ).read, :symbolize_names => true)
  end
end
