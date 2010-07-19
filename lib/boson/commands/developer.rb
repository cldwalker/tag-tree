module Developer
  # Updates example config files with latest config files
  def sync_config
    ['config/machine_tags.yml', 'config/alias.yml'].each do |f|
      system('cp', '-f', f, "#{f}.example")
    end
  end
end
