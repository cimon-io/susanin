require "active_support/core_ext/array"
require "active_support/concern"

module Susanin

  class Resource

    def initialize(values=[])
      @resources = values.dup
    end

    def url_parameters(record_or_hash_or_array, options={})
      params = self.get(Array.wrap(record_or_hash_or_array)).flatten
      merged_options(params, options={})
    end

    #
    # get(
    #   [:a, :c, :d],
    #   [
    #     [[:A, :B], ->(r) {:a}]
    #     [[:A], ->(r) {:q}]
    #     [[:C], ->(r) {:w}]
    #     [[:E], ->(r) {:e}]
    #   ]
    # )
    #
    # [:qwe, :wer, :d]
    #
    def get(record, resources=@resources)
      result = [record, resources]
      new_record, new_resources = replace_with(record, resources)
      if record == new_record
        new_record
      else
        get(new_record, new_resources)
      end
    end

    #
    # replace_with(
    #   [:a, :b, :c, :d],
    #   [
    #     [[:A, :B], ->(r) {:a}]
    #     [[:C], ->(r) {:w}]
    #     [[:E], ->(r) {:e}]
    #   ]
    # )
    #
    #  [
    #   [:a, :c, :d],
    #   [
    #     [[:C], ->(r) {:w}]
    #     [[:E], ->(r) {:e}]
    #   ]
    #  ]
    #
    def replace_with(record, resources)
      record = record.dup
      resources = resources.dup
      pattern, converter = find_first_pattern(record, resources)

      [replace_subrecord(record, pattern, resources), resources_except(resources, pattern)]
    end

    #
    # find_first_pattern(
    #   [:a, :b, :c, :d],
    #   [
    #     [[:A, :B], ->(r) {:a}]
    #     [[:C], ->(r) {:w}]
    #     [[:E], ->(r) {:e}]
    #   ]
    # )
    #
    # [[:A, :B], ->(r) {:a}]
    #
    def find_first_pattern(record, resources)
      record_patterns = patterns(get_key(record))

      resources.select do |r|
        record_patterns.include?(r[0])
      end.first || []
    end

    #
    # resources_except(
    #   [
    #     [[:A, :B], ->(r) {:a}]
    #     [[:A], ->(r) {:q}]
    #     [[:C], ->(r) {:w}]
    #     [[:E], ->(r) {:e}]
    #   ],
    #   [:A, :B]
    # )
    #
    # [
    #   [[:C], ->(r) {:w}]
    #   [[:E], ->(r) {:e}]
    # ],
    #
    def resources_except(resources, keys)
      keys = Array.wrap(keys)
      new_resources = resources.dup
      new_resources.reject! { |r| contains_subarray?(keys, Array.wrap(r[0])) }
      new_resources
    end

    #
    # get_key(a) => A
    # get_key(A) => A
    # get_key([a]) => [A]
    # get_key([a, B]) => [A, B]
    # get_key([A]) => [A]
    # get_key([A]) => [A]
    # get_key(:qwe) => :qwe
    # get_key([:qwe]) => [:qwe]
    # get_key('qwe') => 'qwe'
    #
    def get_key(record)
      case record
        when Class then record
        when Array then record.map { |i| get_key(i) }
        when Symbol then record
        when String then record
        else record.class
      end
    end

    def get_value(record, resources)
      key = get_key(record)
      resource = resources.find { |i| i[0] == key }
      resource ? resource[1] : record
    end

    #
    # merged_options([], {}) #=> []
    # merged_options([a], {}) #=> [a]
    # merged_options([a, {}], {}) #=> [a]
    # merged_options([a, {a: 1}], {}) #=> [a, {a: 1}]
    # merged_options([a, {}], {a: 1}) #=> [a, {a: 1}]
    # merged_options([a, {a: 1}], {a: 2}) #=> [a, {a: 1}]
    #
    def merged_options(params, options={})
      params = params.dup
      default_options = params.extract_options!
      params + ((default_options.any? || options.any?) ? [default_options.merge(options)] : [])
    end

    #
    # contains_subarray?([1,2,3,4,5], [1,2,3]) => true
    # contains_subarray?([1,2,3,4,5], [3,4]) => true
    # contains_subarray?([1,2,3,4,5], [1,3,4]) => false
    # contains_subarray?([1,2,3,4,5], 5) => true
    #
    def contains_subarray?(source, subarray)
      source = Array.wrap(source)
      subarray = Array.wrap(subarray)
      iteration_count = source.length - subarray.length
      0.upto(iteration_count).any? do |i|
        source[i..(i+subarray.length-1)] == subarray
      end
    end

    def patterns(arr)
      Pattern.new(arr)
    end

    #
    # replace_subrecord(
    #   [:a, :b, :c, :a, :b, :b],
    #   [:a, :b],
    #   ->(){ '_1_' }
    # )
    #
    # ['_1_', :c, '_1_', :b]
    #
    def replace_subrecord(record, pattern, resource)
      record = record.dup
      pattern = Array.wrap(pattern)

      i = pattern.length

      while i <= record.length do
        set = (0+(i-pattern.length))..(i-1)
        subset = record[set]

        if pattern_match?(subset, pattern)
          subset = subset[0] if subset.size == 1
          value = get_value(subset, resource).call(subset)
          record[set] = value
          i += value.size
        else
          i += 1
        end
      end

      record
    end

    #
    # pattern_match?([a, b], [A, B]) => true
    # pattern_match?([a, b], [a, b]) => false
    #
    def pattern_match?(record, pattern)
      Array.wrap(get_key(record)) == Array.wrap(pattern)
    end

    def array_unwrap(a)
      a.size == 1 ? a[0] : a
    end

  end

end
