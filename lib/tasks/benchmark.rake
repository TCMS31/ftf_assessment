# frozen_string_literal: true

require 'benchmark'

namespace :benchmark do
  desc 'Compare ArithmeticOperations against the original repeated-addition implementation'
  task :arithmetic do
    require_relative '../arithmetic_operations'

    # The implementation this repo shipped originally, kept here purely as the
    # benchmark baseline. `multiply` looped once per unit of the second operand.
    repeated_addition = Class.new do
      def multiply(num1, num2)
        negative = num1.negative? ^ num2.negative?
        num1 = num1.abs
        num2 = num2.abs
        result = 0
        while num2.positive?
          result += num1
          num2 -= 1
        end
        negative ? -result : result
      end

      def power(base, exponent)
        result = 1
        exponent.times { result = multiply(result, base) }
        result
      end
    end.new

    current = ArithmeticOperations.new

    cases = [
      ['multiply(2, 1_000_000)', ->(impl) { impl.multiply(2, 1_000_000) }],
      ['multiply(2, 10_000_000)', ->(impl) { impl.multiply(2, 10_000_000) }],
      ['multiply(123_456, 98_765)', ->(impl) { impl.multiply(123_456, 98_765) }],
      ['power(2, 64)', ->(impl) { impl.power(2, 64) }]
    ]

    puts format('%-28s %14s %14s %10s', 'case', 'repeated-add', 'shift-and-add', 'speedup')
    puts '-' * 70

    cases.each do |label, block|
      old_time = Benchmark.realtime { block.call(repeated_addition) }
      new_time = Benchmark.realtime { block.call(current) }
      raise "results disagree for #{label}" unless block.call(repeated_addition) == block.call(current)

      puts format('%-28s %13.6fs %13.6fs %9.0fx', label, old_time, new_time, old_time / new_time)
    end

    puts
    puts "ruby #{RUBY_VERSION} on #{RUBY_PLATFORM}"
  end
end
