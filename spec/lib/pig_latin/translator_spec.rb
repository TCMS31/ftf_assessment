# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PigLatin::Translator do
  describe '.translate_word' do
    it 'moves a single leading consonant to the end' do
      expect(described_class.translate_word('hello')).to eq('ellohay')
    end

    it 'moves a whole leading consonant cluster' do
      expect(described_class.translate_word('string')).to eq('ingstray')
    end

    it 'suffixes a vowel-initial word with "way"' do
      expect(described_class.translate_word('apple')).to eq('appleway')
    end

    it 'preserves a leading capital' do
      expect(described_class.translate_word('Hello')).to eq('Ellohay')
    end

    it 'preserves an all-caps word' do
      expect(described_class.translate_word('NASA')).to eq('ASANAY')
    end

    # Regression: the original implementation treated the opening quote as part
    # of the consonant cluster and produced 'e"shay'.
    it 'keeps a leading quotation mark in front of the translated word' do
      expect(described_class.translate_word('"she')).to eq('"eshay')
    end

    # Regression: trailing punctuation was carried into the cluster, producing
    # 'ow"knay' and 'uffix.[1]say'.
    it 'keeps trailing punctuation at the end of the translated word' do
      expect(described_class.translate_word('know"')).to eq('owknay"')
      expect(described_class.translate_word('suffix.[1]')).to eq('uffixsay.[1]')
      expect(described_class.translate_word('example,')).to eq('exampleway,')
    end

    it 'treats a non-initial "y" as a vowel' do
      expect(described_class.translate_word('syllable')).to eq('yllablesay')
      expect(described_class.translate_word('rhythm')).to eq('ythmrhay')
    end

    it 'treats an initial "y" as a consonant' do
      expect(described_class.translate_word('yellow')).to eq('ellowyay')
    end

    it 'returns a token with no letters unchanged' do
      expect(described_class.translate_word('1899')).to eq('1899')
      expect(described_class.translate_word('--')).to eq('--')
      expect(described_class.translate_word('')).to eq('')
    end

    it 'handles a word with no vowels' do
      expect(described_class.translate_word('nth')).to eq('nthay')
    end
  end

  describe '.translate' do
    it 'translates a sentence word by word' do
      expect(described_class.translate('Hello world')).to eq('Ellohay orldway')
    end

    # The Wikipedia "Pig Latin" article states this exact expected output, which
    # makes it the best possible end-to-end assertion for the rules.
    it 'reproduces the example given by the Wikipedia article' do
      expect(described_class.translate('"she does not know"')).to eq('"eshay oesday otnay owknay"')
    end

    it 'preserves whitespace runs and line breaks' do
      expect(described_class.translate("Hello  world\n\nNext para"))
        .to eq("Ellohay  orldway\n\nExtnay arapay")
    end

    it 'returns an empty string for nil or empty input' do
      expect(described_class.translate(nil)).to eq('')
      expect(described_class.translate('')).to eq('')
    end
  end
end
