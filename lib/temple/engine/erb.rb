require 'erb'

module Temple
  class Engine
    # An engine which works in-place for ERB:
    # 
    #   require 'temple'
    #   
    #   template = Temple::Engine::ERB.new("<%= 1 + 1 %>")
    #   template.result # => "2"
    class ERB < ::ERB
      OriginalERB = ::ERB
      Optimizers = [Filters::StaticMerger, Filters::DynamicInliner]
      
      # The optional _filename_ argument passed to Kernel#eval when the ERB code
      # is run
      attr_accessor :filename
      
      # The Ruby code generated by ERB
      attr_reader :src
      
      # The sexp generated by Temple
      attr_reader :sexp
      
      # The optimized sexp generated by Temple
      attr_reader :optimized_sexp
      
      # Sets the ERB constant to Temple::Engine::ERB
      # 
      # Example:
      # 
      #   require 'temple'
      #   Temple::Engine::ERB.rock!
      #   ERB == Temple::Engine::ERB
      def self.rock!
        Object.send(:remove_const, :ERB)
        Object.send(:const_set, :ERB, self)
      end
      
      # Sets the ERB constant back to regular ERB
      # 
      # Example:
      # 
      #   require 'temple'
      #   original_erb = ERB
      #   Temple::Engine::ERB.rock!
      #   ERB.suck!
      #   ERB == original_erb
      
      def self.suck!
        Object.send(:remove_const, :ERB)
        Object.send(:const_set, :ERB, OriginalERB)
      end
      
      def initialize(str, safe_level = nil, trim_mode = nil, eoutvar = '_erbout')
        @parser = Parsers::ERB.new(:trim_mode => trim_mode)
        @compiler = Core::ArrayBuffer.new(:buffer => eoutvar)
        @safe_level = safe_level
        
        @sexp = @parser.compile(str)
        @optimized_sexp = Optimizers.inject(@sexp) { |m, e| e.new.compile(m) }
        @src = @compiler.compile(@optimized_sexp)
      end
    end
  end
end