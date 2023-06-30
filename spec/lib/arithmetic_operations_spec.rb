# frozen_string_literal: true

require 'rails_helper'
require_relative '../../lib/arithmetic_operations'

RSpec.describe ArithmeticOperations do
  subject(:arithmetic) { described_class.new }

  describe '#multiply' do
    it 'multiplies two positive numbers' do
      expect(arithmetic.multiply(2, 10)).to eq(20)
    end

    it 'multiplies a positive and a negative number' do
      expect(arithmetic.multiply(10, -2)).to eq(-20)
      expect(arithmetic.multiply(-10, 2)).to eq(-20)
    end

    it 'multiplies two negative numbers' do
      expect(arithmetic.multiply(-2, -10)).to eq(20)
    end

    it 'returns zero when either operand is zero' do
      expect(arithmetic.multiply(5, 0)).to eq(0)
      expect(arithmetic.multiply(0, 5)).to eq(0)
      expect(arithmetic.multiply(0, 0)).to eq(0)
    end

    it 'agrees with Ruby over a range of operands' do
      [[123_456, 98_765], [-7, 13], [1, 1], [999, -999], [2, 1_000_000]].each do |a, b|
        expect(arithmetic.multiply(a, b)).to eq(a * b)
      end
    end

    it 'handles operands beyond 64 bits' do
      big = 12_345_678_901_234_567_890
      expect(arithmetic.multiply(big, big)).to eq(big * big)
    end

    # Regression: repeated addition made the cost proportional to the *value* of
    # the second operand, so multiply(2, 1_000_000) did a million additions.
    it 'is fast regardless of which operand is large' do
      expect { Timeout.timeout(1) { arithmetic.multiply(2, 100_000_000) } }.not_to raise_error
    end

    it 'refuses non-integer operands instead of returning a wrong answer' do
      expect { arithmetic.multiply(2.5, 2) }.to raise_error(TypeError, /num1/)
      expect { arithmetic.multiply(2, '3') }.to raise_error(TypeError, /num2/)
    end
  end

  describe '#power' do
    it 'raises a number to a power' do
      expect(arithmetic.power(2, 4)).to eq(16)
      expect(arithmetic.power(3, 5)).to eq(243)
    end

    it 'returns 1 for a zero exponent' do
      expect(arithmetic.power(2, 0)).to eq(1)
      expect(arithmetic.power(0, 0)).to eq(1)
    end

    it 'handles a negative base' do
      expect(arithmetic.power(-2, 3)).to eq(-8)
      expect(arithmetic.power(-2, 4)).to eq(16)
    end

    it 'agrees with Ruby for large exponents' do
      expect(arithmetic.power(2, 64)).to eq(2**64)
      expect(arithmetic.power(7, 100)).to eq(7**100)
    end

    # Regression: `exponent.times` yields nothing for a negative exponent, so
    # power(2, -1) silently returned 1 instead of refusing.
    it 'refuses a negative exponent rather than answering 1' do
      expect { arithmetic.power(2, -1) }.to raise_error(ArgumentError, /exponent must be >= 0/)
    end

    it 'refuses non-integer arguments' do
      expect { arithmetic.power(2.0, 3) }.to raise_error(TypeError)
      expect { arithmetic.power(2, 3.0) }.to raise_error(TypeError)
    end

    it 'stays fast for a large exponent' do
      expect { Timeout.timeout(1) { arithmetic.power(7, 4096) } }.not_to raise_error
    end
  end
end
