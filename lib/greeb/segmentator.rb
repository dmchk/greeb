# encoding: utf-8

# It is possible to perform simple sentence detection that is based
# on Greeb's tokenization.
#
class Greeb::Segmentator
  # Sentence does not start from the separator charater, line break
  # character, and punctuation characters.
  #
  SENTENCE_DOESNT_START = [:separ, :break, :punct, :spunct]

  attr_reader :tokens

  # Create a new instance of {Greeb::Segmentator}.
  #
  # @param tokenizer_or_tokens [Greeb::Tokenizer,Set] an instance of
  # Greeb::Tokenizer or set of its results.
  #
  def initialize tokenizer_or_tokens
    @tokens = if tokenizer_or_tokens.is_a? Greeb::Tokenizer
      tokenizer_or_tokens.tokens
    else
      tokenizer_or_tokens
    end
  end

  # Sentences memoization method.
  #
  # @return [Set<Greeb::Entity>] a set of sentences.
  #
  def sentences
    detect_sentences! unless @sentences
    @sentences
  end

  # Extract tokens from the set of sentences.
  #
  # @param sentences [Array<Greeb::Entity>] a list of sentences.
  #
  # @return [Hash<Greeb::Entity, Array<Greeb::Entity>>] a hash with
  # sentences as keys and tokens arrays as values.
  #
  def extract *sentences
    Hash[
      sentences.map do |s|
        [s, tokens.select { |t| t.from >= s.from and t.to <= s.to }]
      end
    ]
  end

  protected
    # Implementation of the sentence detection method. This method
    # changes the `@sentences` ivar.
    #
    # @return [nil] nothing.
    #
    def detect_sentences!
      @sentences = SortedSet.new

      rest = tokens.inject(new_sentence) do |sentence, token|
        if !sentence.from and SENTENCE_DOESNT_START.include?(token.type)
          next sentence
        end

        sentence.from = token.from unless sentence.from

        next sentence if sentence.to and sentence.to > token.to

        if :punct == token.type
          sentence.to = tokens.
            select { |t| t.from >= token.from }.
            inject(token) { |r, t| break r if t.type != token.type; t }.
            to

          @sentences << sentence
          sentence = new_sentence
        elsif :separ != token.type
          sentence.to = token.to
        end

        sentence
      end

      nil.tap { @sentences << rest if rest.from and rest.to }
    end

  private
    # Create a new instance of {Greeb::Entity} with `:sentence` type.
    #
    # @return [Greeb::Entity] a new entity instance.
    #
    def new_sentence
      Greeb::Entity.new(nil, nil, :sentence)
    end
end
