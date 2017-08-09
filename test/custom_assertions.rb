require 'minitest/assertions'

module Minitest
  module Assertions
    def assert_sameish_hash(expected, actual, msg = nil)
      assert(
        expected.is_a?(Hash) && actual.is_a?(Hash),
        'Inputs must be instances of Hash'
      )
      assert(
        expected.keys.size == actual.keys.size,
        "Expected hash with #{expected.keys.size} keys, " \
        "got hash with #{actual.keys.size} keys.\n" \
        "Expected: #{expected}\nActual: #{actual}"
      )
      assert_equal(stringify_keys(expected), stringify_keys(actual), msg)
    end

    private

    def stringify_keys(object)
      if object.is_a? Hash
        object.each_with_object({}) do |(key, value), result|
          result[key.to_s] = stringify_keys value
        end
      elsif object.is_a? Array
        object.map { |obj| stringify_keys obj }
      else
        object
      end
    end
  end
end
