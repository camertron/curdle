require 'parser/current'

module Curdle
  autoload :RemoveSorbet, 'curdle/remove_sorbet'
  autoload :Tasks,        'curdle/tasks'

  def self.process_file(file)
    code = File.read(file)
    File.write(file, process(code, file))
  end

  def self.process(code, filename = '(curdle)')
    ast = Parser::CurrentRuby.parse(code)
    buffer = Parser::Source::Buffer.new(filename, source: code)
    rewriter = Curdle::RemoveSorbet.new
    rewriter.rewrite(buffer, ast)
  end
end
