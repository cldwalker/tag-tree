module StartRails
  def self.config
    {:object_methods=>false}
  end

  def self.after_included
    ENV['RAILS_ENV'] ||= 'local'
    require File.dirname(__FILE__) + '/../../../config/boot'
    require ::RAILS_ROOT + '/config/environment'
  end
end