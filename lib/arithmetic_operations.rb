# frozen_string_literal: true

# Integer multiplication and exponentiation built from addition only.
#
# The exercise is to implement `multiply` and `power` without reaching for `*`
# or `**`. The naive way to honour that is repeated addition, which is what the
# first version did: `multiply(a, b)` looped `b` times. That is correct but
# linear in the *value* of the operand, so `multiply(2, 1_000_000)` performed a
# million additions while `multiply(1_000_000, 2)` performed two — the same
# product, five orders of magnitude apart in work.
#
# Both methods here are logarithmic in the operand instead:
#
#   * `multiply` uses the Russian peasant / shift-and-add algorithm: halve one
#     operand, double the other, and accumulate whenever the halved operand is
#     odd. O(log b) additions.
#   * `power` uses exponentiation by squaring, O(log n) multiplications.
#
# Halving and doubling are done with `+`, integer division and bit tests, so the
# no-`*`/no-`**` constraint still holds.
class ArithmeticOperations
  # @param num1 [Integer]
  # @param num2 [Integer]
  # @return [Integer] num1 * num2
  # @raise [TypeError] unless both operands are integers
  def multiply(num1, num2)
    a = integer!(num1, :num1)
    b = integer!(num2, :num2)

    negative = a.negative? ^ b.negative?
    product = unsigned_multiply(a.abs, b.abs)

    negative ? -product : product
  end

  # @param base [Integer]
  # @param exponent [Integer] must be zero or positive
  # @return [Integer] base ** exponent
  # @raise [ArgumentError] on a negative exponent
  #
  # A negative exponent has no integer answer. The previous version silently
  # returned 1 for every negative exponent, because `(-3).times` yields nothing;
  # `power(2, -1)` claimed 2**-1 == 1. Refusing is the only honest option for an
  # integer-only implementation.
  def power(base, exponent)
    b = integer!(base, :base)
    n = integer!(exponent, :exponent)
    raise ArgumentError, "exponent must be >= 0, got #{n}" if n.negative?

    result = 1
    factor = b

    while n.positive?
      result = multiply(result, factor) if n.odd?
      n /= 2
      factor = multiply(factor, factor) if n.positive?
    end

    result
  end

  private

  # Russian peasant multiplication on non-negative operands.
  def unsigned_multiply(multiplicand, multiplier)
    product = 0

    while multiplier.positive?
      product += multiplicand if multiplier.odd?
      multiplicand += multiplicand # double
      multiplier /= 2              # halve
    end

    product
  end

  def integer!(value, name)
    return value if value.is_a?(Integer)

    raise TypeError, "#{name} must be an Integer, got #{value.class}"
  end
end
