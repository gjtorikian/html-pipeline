require 'gemojione'
require 'rails'

module Gemojione
  class Railtie < Rails::Railtie
    initializer "gemojione.defaults" do
      Gemojione.asset_host = ActionController::Base.asset_host
      Gemojione.asset_path = '/assets/emoji'
    end

    rake_tasks do
      load File.absolute_path(File.dirname(__FILE__) + '/tasks/install.rake')
    end
  end
end
