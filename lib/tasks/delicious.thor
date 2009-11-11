require 'www/delicious'
# Used to push and pull bookmarks and set bundles tags for delicious account specified by environment variables
# DELICIOUS_USER and DELICIOUS_PASSWORD. 
class Delicious < Thor

  method_options :pretend=>:boolean
  def initialize
    @client = WWW::Delicious.new(ENV['DELICIOUS_USER'], ENV['DELICIOUS_PASSWORD'])

    #setup db
    ENV["RAILS_ENV"] = config[:environment] || 'development'
    require File.dirname(__FILE__) + '/../../config/boot'
    require ::RAILS_ROOT + '/config/environment'
    # require 'lib/boson/commands/active_record_ext'
  end

  desc "push", "Pushes local bookmarks to delicious that have changed since last update."
  def push
    if config[:updated_at]
      urls_to_add = ::Url.find(:all, :conditions=>["updated_at >= ?", config[:updated_at]])
      existing_urls = @client.posts_all.map {|e| e.url.to_s }
      urls_to_delete = urls_to_add.select {|e|
        existing_urls.include?(to_full_delicious_url(e.name))
      }.map {|e| to_full_delicious_url(e.name) }
      delete_urls(urls_to_delete)
      add_urls(urls_to_add)
    else
      puts "Your config doesn't indicate you've ever updated or imported bookmarks. First import."
    end
  end

  # note: urls created on delicious won't have substitutions for &+
  desc "pull", "Pulls delicious bookmarks that don't exist locally"
  def pull
    local_urls = Url.all.map {|e| to_full_delicious_url e.name }
    delicious_urls = @client.posts_all.select {|e| !e.tags.include?('tagaholic') }
    urls_to_add = delicious_urls.select {|e|
      !local_urls.include?(e.url.to_s)
    }
    local_add_urls urls_to_add
  end

  desc "import", "Imports all bookmarks to delicious"
  def import
    add_urls(::Url.all)
  end

  desc "diff", "Shows difference between local + remote urls"
  def diff
    remote = @client.posts_all.map {|e| {:url=>e.url.to_s, :tags=>e.tags.sort} }
    only_local = Url.all.reject {|e| h = {:url=>to_full_delicious_url(e.name), :tags=>e.tag_list.sort}; remote.include?(h) }
    print_table only_local
    puts "Found #{only_local.size} urls"
  end

  desc "add", "Adds url records by their db ids"
  def add(*ids)
    add_urls(Url.find(ids))
  end

  desc "delete", "Deletes url records by their db ids"
  def delete(*ids)
    delete_urls Url.find(e).map {|e| to_full_delicious_url(e.name) }
  end

  desc "bundle", "Puts tags into bundles by namespace. Nonmachine tags go into normal_tags bundle."
  def bundle
    Tag.namespaces.each {|e| @client.bundles_set e, Tag.find(:all, :conditions=>["name REGEXP ?", "#{e}:"]).map(&:name) }
    normal_tags = @client.tags_get.select {|e| e.name !~ /:.*=/ }.map(&:name)
    @client.bundles_set 'normal_tags', normal_tags
  end
  
  desc "touch", "Touches config's updated_at with current time"
  def touch
    write_config(config.merge(:updated_at=>Time.now.utc))
  end

  def print_table(urls)
    if urls[0].is_a?(::Url)
      urls.map {|e| puts e.name + ": "+ e.tag_list.join(",") }
    else
      urls.map {|e| puts e.url.to_s + ": "+ e.tags.join(",") }
    end
  end

  def delete_urls(urls)
    if options[:pretend]
      puts "Would delete #{urls.size} urls: #{urls.join(',')}"
    else
      urls.each {|e| 
        @client.posts_delete(e)
        puts "Deleted #{e}"
      }
    end
  end

  def local_add_urls(urls)
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

  def add_urls(urls)
    if options[:pretend]
      puts "Would add #{urls.size} urls"
      return
    end
    urls.each {|e|
      begin
        @client.posts_add(delicious_hash(e))
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
    File.open(::RAILS_ROOT + '/config/delicious.yml', 'w') {|f| f.write(hash.to_yaml) }
  end

  def config
    @config ||= YAML::load_file(::RAILS_ROOT + '/config/delicious.yml') rescue {}
  end

  def client(*args)
    p @client.send(*args)
  end

  def debug(*args)
    p send(*args)
  end
end
