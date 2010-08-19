module StartRails
  def self.config
    {:object_methods=>false}
  end

  def self.after_included
    ENV['RAILS_ENV'] = 'local' if `git config --get github.user`.chomp == 'cldwalker'
    require File.dirname(__FILE__) + '/../../../config/environment'
  end
end