require 'test_helper'

class SusaninResourceTest < Minitest::Test

  def setup
    @a_klass = Class.new { def inspect; "a_klass##{self.object_id}"; end; def self.inspect; "a_klass"; end; }
    @b_klass = Class.new { def inspect; "b_klass##{self.object_id}"; end; def self.inspect; "b_klass"; end; }
    @c_klass = Class.new { def inspect; "c_klass##{self.object_id}"; end; def self.inspect; "c_klass"; end; }
    @d_klass = Class.new { def inspect; "d_klass##{self.object_id}"; end; def self.inspect; "d_klass"; end; }

    @a = @a_klass.new
    @b = @b_klass.new
    @c = @c_klass.new
    @d = @d_klass.new
  end

  def resource
    @resource ||= ::Susanin::Resource.new()
  end

  def test_patterns_return_pattern_instance
    assert resource.patterns([]).is_a?(::Susanin::Pattern), '#pattern_params should be instance of ::Susanin::Pattern'
  end

  def test_assertion_1
    subject = ::Susanin::Resource.new([
      [:a_prefix, ->(r) { [:global_prefix, r] }],
      [:another_prefix, ->(r) { [:global_prefix, r] }],
      [@a_klass, ->(r) { [:a_prefix, r] }],
      [[@a_klass], ->(r) { [:a_prefix, r] }],
      [[@a_klass, @b_klass], ->(r) { [:another_prefix, *r] }],
      [[@a_klass, :middle_prefix, @c_klass], ->(r) { "result" }]
    ])

    assert_equal subject.url_parameters([@a]), [:global_prefix, :a_prefix, @a]
    assert_equal subject.url_parameters([@a, @b]), [:global_prefix, :a_prefix, :global_prefix, :another_prefix, @a, @b]
    assert_equal subject.url_parameters([@a, :middle_prefix, @c]), [:global_prefix, :a_prefix, "result"]
  end

  def test_get
    subject = ::Susanin::Resource.new()
    resources = [
      [:a_prefix,                            ->(r) { [:global_prefix, r] }],
      [:another_prefix,                      ->(r) { [:global_prefix, r] }],
      [[@a_klass, @b_klass],                 ->(r) { [:another_prefix, *r] }],
      [@a_klass,                             ->(r) { [:a_prefix, r] }],
      [[@a_klass],                           ->(r) { [:arr_prefix, r] }],
      [[@a_klass, :middle_prefix, @c_klass], ->(r) { "result" }]
    ]

    assert_equal subject.get(@a, resources), [:global_prefix, :a_prefix, @a]
    assert_equal subject.get([@a, @b], resources), [:global_prefix, :another_prefix, @a, @b]
    assert_equal subject.get([:a_prefix, :another_prefix, @c], resources), [:global_prefix, :a_prefix, :global_prefix, :another_prefix, @c]
    assert subject.get([:a_prefix, @a], resources), [:global_prefix, :a_prefix, :global_prefix, :a_prefix, @a]
    assert subject.get([:a_prefix, @a], []), [:a_prefix, @a]
  end

  def test_get_key
    subject = ->(*args) { resource.get_key(*args) }
    assert_equal subject['1'], '1'
    assert_equal subject[1], Fixnum
    assert_equal subject[:'1'], :'1'
    assert_equal subject[nil], NilClass
    assert_equal subject[String], String
    assert_equal subject[true], TrueClass
    assert_equal subject[[1, :'1']], [Fixnum, :'1']
    assert_equal subject[[String, 1, :'1', :qwe]], [String, Fixnum, :'1', :qwe]
  end

  def test_replace_with
    resources = [
      [[@a_klass, :middle_prefix, @c_klass], ->(r) { "result" }],
      [:a_prefix,                            ->(r) { [:global_prefix, r] }],
      [:another_prefix,                      ->(r) { [:global_prefix, r] }],
      [@a_klass,                             ->(r) { [:a_prefix, r] }],
      [[@a_klass],                           ->(r) { [:arr_prefix, r] }],
      [[@a_klass, @b_klass],                 ->(r) { [:another_prefix, *r] }]
    ]
    should_behave = ->(resources, record, assert_keys, assert_record) do
      resource.replace_with(record, resources).tap do |arr|
        assert_equal arr.second.map(&:first), assert_keys
        assert_equal arr.first, assert_record
      end
    end

    should_behave.call(resources,
      [@a, @b, @c, @d],
      [[@a_klass, :middle_prefix, @c_klass], :a_prefix, :another_prefix, [@a_klass, @b_klass]],
      [:a_prefix, @a, @b, @c, @d]
    )

    should_behave.call(resources,
      [:a_prefix],
      [[@a_klass, :middle_prefix, @c_klass], :another_prefix, @a_klass, [@a_klass], [@a_klass, @b_klass]],
      [:global_prefix, :a_prefix]
    )

    should_behave.call(resources,
      [:a_prefix, @a],
      [[@a_klass, :middle_prefix, @c_klass], :another_prefix, @a_klass, [@a_klass], [@a_klass, @b_klass]],
      [:global_prefix, :a_prefix, @a]
    )

    should_behave.call(resources,
      [:qwe],
      [[@a_klass, :middle_prefix, @c_klass], :a_prefix, :another_prefix, @a_klass, [@a_klass], [@a_klass, @b_klass]],
      [:qwe]
    )

    should_behave.call(resources,
      [:qwe, @a],
      [[@a_klass, :middle_prefix, @c_klass], :a_prefix, :another_prefix, [@a_klass, @b_klass]],
      [:qwe, :a_prefix, @a]
    )

    should_behave.call(resources,
      [:qwe, @a, :middle_prefix, @c],
      [:a_prefix, :another_prefix, [@a_klass, @b_klass]],
      [:qwe, "result"]
    )
  end

  def test_merged_options
    subject = ::Susanin::Resource.new
    assert subject.merged_options([1, {}], {}), [1]
    assert subject.merged_options([1, {a: 1}], {}), [1, {a: 1}]
    assert subject.merged_options([1, {a: 1}], {b: 2}), [1, {a: 1, b: 2}]
    assert subject.merged_options([1, {a: 1}], {a: 2}), [1, {a: 1}]
  end

  def test_contains_subarray
    subject = ->(*agrs) { resource.contains_subarray?(*agrs) }

    assert  subject[[1,2,3,4,5], [1,2,3]]
    assert  subject[[1,2,3,4,5], [3,4]]
    assert  subject[[1,2,3,4,5], 5]
    assert  subject[[1,2,5], [1,2,5]]
    assert  subject[[1,2,3,4,5,5,6,7,8,9,0], [5,5]]
    dissuade subject[[1,2,3,4,5], [1,3,4]]
    dissuade subject[[1,2], 5]
    dissuade subject[[1,2,5], [1,5]]
  end

  def test_resources_except
    subject = ->(*args) { resource.resources_except(*args).map(&:first).to_set }

    resources = [
      [:a_prefix,                             ->(r) { :qwe }],
      [:another_prefix,                       ->(r) { :wer }],
      [@a_klass,                              ->(r) { :ert }],
      [[@a_klass],                            ->(r) { :newer_happen }], # because array with single element is unwrapped to element
      [[@a_klass, @b_klass],                  ->(r) { :tyu }],
      [[@a_klass, @b_klass, @c_klass],        ->(r) { :tyu }],
      [[@a_klass, :middle_prefix, @c_klass],  ->(r) { :yui }]
    ]

    assert_equal(
      subject[resources, :a_prefix],
      [:another_prefix, @a_klass, [@a_klass], [@a_klass, @b_klass], [@a_klass, @b_klass, @c_klass], [@a_klass, :middle_prefix, @c_klass]].to_set
    )
    assert_equal(
      subject[resources, [@a_klass, @b_klass]],
      [:a_prefix, :another_prefix, [@a_klass, :middle_prefix, @c_klass], [@a_klass, @b_klass, @c_klass]].to_set
    )
    assert_equal(
      subject[resources, [@a_klass, :middle_prefix, @c_klass]],
      [:a_prefix, :another_prefix, [@a_klass, @b_klass], [@a_klass, @b_klass, @c_klass]].to_set
    )
    assert_equal(
      subject[resources, [@a_klass]],
      [:a_prefix, :another_prefix, [@a_klass, @b_klass], [@a_klass, :middle_prefix, @c_klass], [@a_klass, @b_klass, @c_klass]].to_set
    )
    assert_equal(
      subject[resources, [@a_klass, @b_klass, @c_klass]],
      [:a_prefix, :another_prefix, [@a_klass, :middle_prefix, @c_klass]].to_set
    )
  end

  def test_find_first_pattern
    resources = [
      [[@a_klass, @b_klass, @c_klass],        ->(r) { :tyu }],
      [:a_prefix,                             ->(r) { :qwe }],
      [:another_prefix,                       ->(r) { :wer }],
      [[@a_klass, @b_klass],                  ->(r) { :tyu }],
      [@a_klass,                              ->(r) { :ert }],
      [[@a_klass],                            ->(r) { :newer_happen }], # pattern before is totally matched with this
      [[@a_klass, :middle_prefix, @c_klass],  ->(r) { :yui }]
    ]
    subject = ->(record) { resource.find_first_pattern(record, resources) }

    assert_equal subject[[@a, @c, @b]].first,             @a_klass
    assert_equal subject[[@c, @a, @b, :qwe, @c]].first,   [@a_klass, @b_klass]
    assert_equal subject[[@c, :a_prefix]].first,          :a_prefix
    assert_equal subject[[:new, @a, @b_klass, @c]].first, [@a_klass, @b_klass, @c_klass]
    assert_equal subject[[:new, :non_exist]].first,       nil
    assert_equal subject[[@b, @c]].first,                 nil
    assert_equal subject[@a].first,                       @a_klass
  end

  def test_replace_subrecord
    subject = ->(*args, r) { resource.replace_subrecord(*args, ->(*a){ r }) }

    assert_equal subject.call([:a, :b, :c, :a, :b, :b], [:a, :b], '_1_'), ['_1_', :c, '_1_', :b]
    assert_equal subject.call([:a, :b, :c, :a, :b, :b], [:a], '_1_'), ['_1_', :b, :c, '_1_', :b, :b]
    assert_equal subject.call([:a, :b, @a, :a, @b, :b], [@a_klass], '_1_'), [:a, :b, '_1_', :a, @b, :b]
    assert_equal subject.call([:a, :b, @a, :a, @b, :b], [@b_klass, :b], '_1_'), [:a, :b, @a, :a, '_1_']
    assert_equal subject.call([:a, :b, @a, :a, @b, :b], [], '_1_'), [:a, :b, @a, :a, @b, :b]
  end

  def test_pattern_match
    subject = ::Susanin::Resource.new()

    assert subject.pattern_match?([@a, @b], [@a_klass, @b_klass])
    assert subject.pattern_match?([@a, :c], [@a_klass, :c])
    assert subject.pattern_match?(@a, @a_klass)
    assert subject.pattern_match?(:c, :c)
    assert subject.pattern_match?([:c], :c)
    assert subject.pattern_match?(:c, [:c])
    dissuade subject.pattern_match?([@a, @b_klass], [@a, @b_klass])
    dissuade subject.pattern_match?(@a, @a)
    dissuade subject.pattern_match?([@a, :c], [@a, :c])
    dissuade subject.pattern_match?([@a, @b], [@a, @b_klass])
    dissuade subject.pattern_match?([@a, @b], [@a, @b])
    dissuade subject.pattern_match?([@a_klass, @b_klass], [@a, @b])
    dissuade subject.pattern_match?([@a_klass, @b_klass], [@a, @b])
  end

end
