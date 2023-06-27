# frozen_string_literal: true

module PigLatin
  # Pure, dependency-free Pig Latin translation.
  #
  # Rules implemented:
  #   * A word beginning with a vowel gains the suffix "way"  ("apple" -> "appleway").
  #   * Otherwise the leading consonant cluster moves to the end and gains "ay"
  #     ("hello" -> "ellohay", "string" -> "ingstray").
  #   * "y" counts as a vowel everywhere except as the first letter of the word,
  #     which is the conventional English rule ("syllable" -> "yllablesay",
  #     "yellow" -> "ellowyay").
  #   * Leading and trailing non-letters stay where they are, so punctuation and
  #     quoting survive the round trip ("know\"" -> "owknay\"", not "ow\"knay").
  #   * A word with no letters at all (a bare number, "--", an em dash) is returned
  #     untouched rather than given a nonsense suffix.
  #   * Capitalisation of the original first letter is carried over to the result.
  #
  # Everything here is a module function on frozen input: no state, no I/O.
  module Translator
    VOWELS = %w[a e i o u].freeze
    VOWEL_SUFFIX = 'way'
    CONSONANT_SUFFIX = 'ay'

    # Splits a token into (leading non-letters, letters, trailing non-letters).
    WORD_PARTS = /\A([^[:alpha:]]*)([[:alpha:]]*)(.*)\z/m

    module_function

    # Translates a block of text, preserving the original whitespace runs so that
    # paragraphs and line breaks are not collapsed.
    #
    # @param text [String]
    # @return [String]
    def translate(text)
      return '' if text.nil?

      text.to_s.split(/(\s+)/).map { |chunk| chunk.match?(/\A\s*\z/) ? chunk : translate_word(chunk) }.join
    end

    # Translates a single whitespace-delimited token.
    #
    # @param token [String]
    # @return [String]
    def translate_word(token)
      return '' if token.nil?

      prefix, letters, suffix = token.to_s.match(WORD_PARTS).captures
      return token.to_s if letters.empty?

      "#{prefix}#{recase(letters, pig(letters))}#{suffix}"
    end

    # @param letters [String] a run of letters only
    # @return [String] the Pig Latin form, all lower case
    def pig(letters)
      lower = letters.downcase
      split = onset_length(lower)

      return "#{lower}#{VOWEL_SUFFIX}" if split.zero?

      "#{lower[split..]}#{lower[0, split]}#{CONSONANT_SUFFIX}"
    end

    # Number of leading consonants before the first vowel sound.
    #
    # @param lower [String] a lower-cased run of letters
    # @return [Integer] 0 when the word already starts with a vowel
    def onset_length(lower)
      lower.each_char.with_index do |char, position|
        return position if vowel?(char, position)
      end
      lower.length
    end

    # @param char [String] single lower-case letter
    # @param position [Integer] index of the letter within the word
    def vowel?(char, position)
      VOWELS.include?(char) || (char == 'y' && position.positive?)
    end

    # Restores the original word's capitalisation shape.
    def recase(original, translated)
      return translated.upcase if original.length > 1 && original == original.upcase
      return translated.sub(/\A./, &:upcase) if original.match?(/\A[[:upper:]]/)

      translated
    end
  end
end
