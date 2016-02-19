require 'test_helper'

class SusaninResourceTest < Minitest::Test

  def setup
    @a_klass = Class.new { def inspect; "a_klass##{self.object_id}"; end; def self.inspect; "a_klass"; end; }
    @b_klass = Class.new { def inspect; "b_klass##{self.object_id}"; end; def self.inspect; "b_klass"; end; }
    @c_klass = Class.new { def inspect; "c_klass##{self.object_id}"; end; def self.inspect; "c_klass"; end; }

    @a = @a_klass.new
    @b = @b_klass.new
    @c = @c_klass.new
  end

  def resource
    @resource ||= ::Susanin::Resource.new()
  end

  def test_patterns_return_pattern_instance
    assert resource.patterns([]).is_a?(::Susanin::Pattern), '#pattern_params should be instance of ::Susanin::Pattern'
  end

  def test_assertion_1
    raise "Not implemented yet"
    subject = ::Susanin::Resource.new({
      :a_prefix => ->(r) { [:global_prefix, r] },
      :another_prefix => ->(r) { [:global_prefix, r] },
      @a_klass => ->(r) { [:a_prefix, r] },
      [@a_klass] => ->(r) { [:a_prefix, r] },
      [@a_klass, @b_klass] => ->(r) { [:another_prefix, *r] },
      [@a_klass, :middle_prefix, @c_klass] => ->(r) { "result" }
    })

    assert subject.url_parameters([@a]) == [:global_prefix, :a_prefix, @a]
    assert subject.url_parameters([@a, @b]) == [:global_prefix, :another_prefix, @a, @b]
    assert subject.url_parameters([@a, :middle_prefix, @c]) == "result"
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
    raise "Not implemented yet"
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
    assert_equal subject[[:new, :non_exist]],             nil
    assert_equal subject[[@b, @c]],                       nil
    assert_equal subject[@a].first,                       @a_klass
  end

  def test_get
    subject = ::Susanin::Resource.new()
    raise "Not implemented yet"

    # assert subject.get(@a, @resources2).flatten == [:global_prefix, :a_prefix, @a]
    # assert subject.get([@a, @b], @resources2).flatten == [:global_prefix, :another_prefix, @a, @b]
    # assert subject.get([:a_prefix, :another_prefix, @c], @resources2).flatten == [:global_prefix, :a_prefix, :global_prefix, :another_prefix, @c]
    # assert subject.get([:a_prefix, @a], @resources2).flatten == [:global_prefix, :a_prefix, :global_prefix, :a_prefix, @a]
  end

end
