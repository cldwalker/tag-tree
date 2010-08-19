module StartRails
  def self.config
    {:object_methods=>false}
  end

  def self.after_included
    Rails.env = 'local' if ENV['RAILS_ENV'] == 'local'
    require File.dirname(__FILE__) + '/../../../config/environment'
  end
end