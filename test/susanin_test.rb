require 'test_helper'

class SusaninTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Susanin::VERSION
  end

  def test_that_has_class_method_susanin
    a1 = Class.new do
      def self.helper_method(*args); end
      def self.hide_action(*args); end
      def polymorphic_url(*args); end
      def polymorphic_path(*args); end
    end


    b1 = Class.new(a1) do
      include ::Susanin
    end

    assert b1.respond_to?(:susanin), 'class should have method #susanin'
    assert b1.new.susanin.is_a?(::Susanin::Resource), 'instance#susanin should be instance of Resource'
  end

end
