require 'test_helper'

class SusaninPatternTest < Minitest::Test

  def test_initialize_with_array
    assert ::Susanin::Pattern.new([]), 'should receive empty array'
    assert ::Susanin::Pattern.new([1,2,3]), 'should receive various array'
    assert ::Susanin::Pattern.new([Object.new,'2',:'3', 4]), 'should receive various array'
  end

  def test_assertion_1
    assert ::Susanin::Pattern.new([]), []
  end

  def test_assertion_2
    assert ::Susanin::Pattern.new([1]), [1]
  end

  def test_assertion_3
    pattern = ::Susanin::Pattern.new([1, 2])
    assert pattern.count == 3
    assert pattern.include?(1)
    assert pattern.include?(2)
    assert pattern.include?([1,2])
  end

  def test_assertion_4
    pattern = ::Susanin::Pattern.new([1, 2, 3])
    assert pattern.count == 6
    assert pattern.include?(1)
    assert pattern.include?(2)
    assert pattern.include?(3)
    assert pattern.include?([1,2])
    assert pattern.include?([2,3])
    assert pattern.include?([1,2,3])
  end

  def test_assertion_5
    pattern = ::Susanin::Pattern.new([:a, :b, :c, :d])
    assert pattern.count == 10
    assert pattern.to_a == [
      [:a,:b,:c,:d],
      [:a,:b,:c],
      [:b,:c,:d],
      [:a,:b],
      [:b,:c],
      [:c,:d],
      :a,
      :b,
      :c,
      :d
    ]
  end

  def test_shift_1
    assert ::Susanin::Pattern.new([]).shifts == []
  end

  def test_shift_2
    assert ::Susanin::Pattern.new([1]).shifts == [[0, 1]]
  end

  def test_shift_3
    shifts = ::Susanin::Pattern.new([1,2]).shifts
    assert shifts.include?([0, 2])
    assert shifts.include?([0, 1])
    assert shifts.include?([1, 1])
  end

  def test_shift_4
    shifts = ::Susanin::Pattern.new([1,2,3]).shifts
    assert shifts.include?([0, 3])
    assert shifts.include?([0, 2])
    assert shifts.include?([1, 2])
    assert shifts.include?([0, 1])
    assert shifts.include?([1, 1])
    assert shifts.include?([2, 1])
  end

  def test_inspect
    subject = ->(*args) { ::Susanin::Pattern.new(*args).inspect }
    assert_equal subject[[1,2,3]], [[1, 2, 3], [1, 2], [2, 3], 1, 2, 3]
    assert_equal subject[[:a,:b]], [[:a, :b], :a, :b]
  end

end
