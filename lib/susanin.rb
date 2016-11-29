require "active_support/core_ext/array"
require "active_support/concern"
require "active_support/dependencies/autoload"
require "susanin/version"

module Susanin
  extend ActiveSupport::Concern

  autoload :Resource, 'susanin/resource'
  autoload :Pattern, 'susanin/pattern'

  included do
    helper_method :polymorphic_url, :polymorphic_path
  end

  module ClassMethods
    def susanin(content = nil, &block)
      content_proc = block_given? ? Proc.new(&block) : Proc.new { content }

      define_method :susanin do
        @susanin ||= Resource.new(Array.wrap(instance_exec(&content_proc)))
      end
    end
  end

  def polymorphic_url(record_or_hash_or_array, options={})
    params = susanin_converter(record_or_hash_or_array, options)

    if (params.first.size == 1) && params.first[0].is_a?(String)
      params.first.first
    else
      super(*params)
    end
  end

  def polymorphic_path(record_or_hash_or_array, options={})
    params = susanin_converter(record_or_hash_or_array, options)

    if (params.first.size == 1) && params.first[0].is_a?(String)
      params.first.first
    else
      super(*params)
    end
  end

  def susanin_converter(record_or_hash_or_array, options={})
    params = susanin.url_parameters(Array.wrap(record_or_hash_or_array))
    params_options = params.extract_options!
    [params, options.merge(params_options)]
  end

  def susanin
    @susanin ||= Resource.new()
  end
end
