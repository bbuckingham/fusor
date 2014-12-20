module FusorUi
  class Engine < ::Rails::Engine
    engine_name 'fusor_ui'

#    initializer "static assets" do |app|
#      app.middleware.insert_before(::ActionDispatch::Static, ::ActionDispatch::Static, "#{config.root}/public")
#    end

    initializer 'fusor_ui.register_plugin', :after=> :finisher_hook do |app|
      Foreman::Plugin.register :fusor_ui do
        requires_foreman '>= 1.4'

        # Add permissions (TODO - do we need to set permissions here)
        # security_block :fusor do
        #   permission :view_fusor, {:'fusor/deployments' => [:r] }
        # end

        # Add role (TODO - will there be a rails called view_fusor)
        # role "FusorUi", [:view_fusor]

        sub_menu :top_menu, :fusor_menu, :caption => N_('Fusor Installer'), :after => :infrastructure_menu do
          menu :top_menu, :fusor_deployments,
               :url_hash => { :controller => 'fusor_ui/deployments', :action => :index },
               :caption  => N_('Deployments')
          menu :top_menu, :new_fusor_deployment,
               :url_hash => { :controller => 'fusor_ui/deployments', :action => :new },
               :caption  => N_('New Deployment')
        end

      end
    end

#    initializer "fusor_ui.assets.precompile" do |app|
#      app.config.assets.precompile += %w(fusor_ui/fusor_ui.css fusor_ui/fusor_ui.js)
#    end

#    initializer 'fusor_ui.configure_assets', :group => :all do
#      SETTINGS[:fusor_ui] =
#        { :assets => { :precompile => ['fusor_ui/fusor_ui.css',
#                                       'fusor_ui/fusor_ui.js'] } }
#    end

    initializer 'fusor_ui.assets_dispatcher', :before => :build_middleware_stack do |app|
      app.middleware.use ::ActionDispatch::Static, "#{FusorUi::Engine.root}/app/assets/javascripts/fusor_ui"
    end

    initializer "fusor_ui.assets", :group => :all do |app|
      if Rails.env.production?
        app.config.assets.paths << "#{FusorUi::Engine.root}/vendor/assets/stylesheets/fusor_ui"
      else
        app.config.less.paths << "#{FusorUi::Engine.root}/vendor/assets/stylesheets/fusor_ui"
      end
    end

    initializer "fusor_ui.plugin", :group => :all do |app|
      SETTINGS[:fusor_ui] = {:assets => {}} if SETTINGS[:fusor_ui].nil?

      SETTINGS[:fusor_ui][:assets][:precompile] = [
        'fusor_ui/fusor-demo.css',
        'fusor_ui/vendor-fusor.css',
        'fusor_ui/bootstrap.css.map',
        'fusor_ui/fusor-demo.js',
        'fusor_ui/vendor-fusor.js'
      ]
    end

  end
end
