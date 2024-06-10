if Rails.env.development? || Rails.env.test?
  require Rails.root.join('lib', 'profiler')

  ActiveSupport.on_load(:action_controller) do
    include Profiler
  end
end
