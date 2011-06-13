
module RealtyYandex
  class Engine < Rails::Engine

    config.autoload_paths += %W(#{config.root}/lib)

    def self.activate
      Rails.env.production? ? require(c) : load(c)
    end

    rake_tasks do
      load File.join(File.dirname(__FILE__), "tasks/yandex_market.rake")
    end

    config.to_prepare &method(:activate).to_proc
  end
  
end
