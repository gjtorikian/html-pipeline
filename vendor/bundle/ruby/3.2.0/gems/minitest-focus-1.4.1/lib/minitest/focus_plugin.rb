# frozen_string_literal: true

module Minitest
  def self.plugin_focus_options opts, options
    opts.on "--no-focus", "Disable `focus` calls in tests." do |n|
      @nofocus = true
    end
  end

  def self.plugin_focus_init options # :nodoc:
    return unless Minitest::Test.respond_to? :filtered_names
    return if Minitest::Test.filtered_names.empty?

    if options[:include] || options[:filter] then
      order = %w[ `focus` --name ]
      a, b = @nofocus ? order : order.reverse
      extra = " Use --no-focus to override." unless @nofocus
      warn "Ignoring #{a} filters in favor of #{b} filters.#{extra}"
      warn ""
    end

    return if @nofocus

    re = "/^(#{Regexp.union(Minitest::Test.filtered_names).source})$/"
    options[:include] = options[:filter] = re
  end
end
