# Used to push and pull bookmarks and set bundles tags for delicious account specified by environment variables
# DELICIOUS_USER and DELICIOUS_PASSWORD. 
module Delicious
  def self.included(mod)
    require 'www/delicious'
  end

  def self.config
    {:namespace=>'d', :dependencies=>['active_record_ext'], :object_methods=>false}
  end

  # @options :pretend=>:boolean, :diff=>:boolean
  # Pushes local bookmarks to delicious that have changed since last update
  def push(options={})
    if Delicious.store[:updated_at]
      urls_to_add = options[:diff] ? diff :
        Url.find(:all, :conditions=>["updated_at >= ?", Delicious.store[:updated_at]])
      existing_urls = client.posts_all.map {|e| e.url.to_s }
      urls_to_delete = urls_to_add.select {|e|
        existing_urls.include?(Delicious.to_full_delicious_url(e.name))
      }.map {|e| Delicious.to_full_delicious_url(e.name) }
      Delicious.delete_urls(urls_to_delete, options)
      Delicious.add_urls(urls_to_add, options)
    else
      puts "Your config doesn't indicate you've ever updated or imported bookmarks. First import."
    end
  end

  # Shows difference between local + remote urls
  def diff
    remote = client.posts_all.map {|e| {:url=>e.url.to_s, :tags=>e.tags.sort} }
    Url.all.reject {|e| h = {:url=>Delicious.to_full_delicious_url(e.name), :tags=>e.tag_list.sort}; remote.include?(h) }
  end

  # Puts tags into bundles by namespace. Nonmachine tags go into normal_tags bundle.
  def bundle
    Tag.namespaces.each {|e| client.bundles_set e, Tag.find(:all, :conditions=>["name REGEXP ?", "#{e}:"]).map(&:name) }
    normal_tags = client.tags_get.select {|e| e.name !~ /:.*=/ }.map(&:name)
    client.bundles_set 'normal_tags', normal_tags
  end

  # note: urls created on delicious won't have substitutions for &+
  # @options :pretend=>:boolean
  # Pulls delicious bookmarks that don't exist locally
  def pull(options={})
    local_urls = Url.all.map {|e| Delicious.to_full_delicious_url e.name }
    delicious_urls = client.posts_all.select {|e| !e.tags.include?('tagaholic') }
    urls_to_add = delicious_urls.select {|e|
      !local_urls.include?(e.url.to_s)
    }
    Delicious.local_add_urls urls_to_add, options
  end

  # Adds url records by their db ids
  def add(*ids)
    Delicious.add_urls(Url.find(ids))
  end

  # Deletes url records by their db ids
  def delete(*ids)
    Delicious.delete_urls Url.find(e).map {|e| Delicious.to_full_delicious_url(e.name) }
  end

  # Touches config's updated_at with current time
  def touch
    Delicious.write_config(Delicious.store.merge(:updated_at=>Time.now.utc))
  end

  # Imports all bookmarks to delicious
  def import
    Delicious.add_urls(Url.all)
  end

  class <<self
    def delete_urls(urls, options={})
      if options[:pretend]
        puts "Would delete #{urls.size} urls: #{urls.join(',')}"
      else
        urls.each {|e| 
          client.posts_delete(e)
          puts "Deleted #{e}"
        }
      end
    end

    def local_add_urls(urls, options={})
      if options[:pretend]
        puts "Would add #{urls.size} urls"
        return
      end
      urls.each {|e|
        begin
          Url.create(:name=>e.url.to_s, :tag_list=>e.tags, :description=>e.notes, :created_at=>e.time)
          puts "Created #{e.url}"
        rescue
          puts "#{e.url}: #{$!}" 
        end
      }
    end

    def add_urls(urls, options={})
      if options[:pretend]
        puts "Would add #{urls.size} urls"
        return
      end
      urls.each {|e|
        begin
          client.posts_add(delicious_hash(e))
          puts "Added #{e.name}"
        rescue
          puts("#{e.id}: #{$!}")
        end
      }
      write_config(config.merge(:updated_at=>Time.now.utc))
      puts "Added #{urls.size} urls"
    end
    
    def to_full_delicious_url(url)
      to_delicious_url(url).gsub(/(\.(com|org|br|us|fm|gov|net|lt|edu|ac|info))$/, '\1/')
    end

    def to_delicious_url(url)
      #URI.escape(url, "+%-_.!~*'();/?:@&=$,[]")
      URI.escape(url, "+&")
    end

    def delicious_hash(url)
      {:url=>to_delicious_url(url.name),:title=>url.name, :notes=>url.description, :tags=>url.tag_list, :time=>url.created_at}
    end

    def write_config(hash)
      File.open(APP_ROOT + 'config/delicious.yml', 'w') {|f| f.write(hash.to_yaml) }
    end

    def store
      @config ||= YAML::load_file(APP_ROOT + 'config/delicious.yml') rescue {}
    end

    def client
      @client ||= WWW::Delicious.new(ENV['DELICIOUS_USER'], ENV['DELICIOUS_PASSWORD'])
    end
  end

  private
  def client
    Delicious.client
  end
end
