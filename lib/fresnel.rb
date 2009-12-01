require File.dirname(Pathname.new(__FILE__).realpath) + "/lighthouse"
require File.dirname(Pathname.new(__FILE__).realpath) + "/date_parser"
require File.dirname(Pathname.new(__FILE__).realpath) + "/cache"

require 'activesupport'
require 'terminal-table/import'
require 'highline/import'

class Fresnel
  attr_reader :global_config_file, :project_config_file, :app_description
  attr_accessor :lighthouse, :current_project_id, :cache, :cache_timeout
  
  def initialize(options=Hash.new)
    @global_config_file="#{ENV['HOME']}/.fresnel"
    @project_config_file=File.expand_path('.fresnel')
    @app_description="A lighthouseapp console manager"
    @lighthouse=Lighthouse
    Lighthouse.account, Lighthouse.token = load_global_config
    @current_project_id=load_project_config
    @cache=Cache.new(:active=>options[:cache]||false, :timeout=>options[:cache_timeout]||5.minutes)
  end
  
  def global_config_wizard
    config=Hash.new
    puts "================================================"
    puts "    Fresnel - #{self.app_description}           "
    puts "                config wizard                   "
    puts "================================================"
    puts
    config['account']=ask("My lighthouse account is : ") do |q|
      q.validate = /^\w+$/ 
      q.responses[:not_valid]="\nError :\nThat seems to be incorrect, we would like to have the <account> part in\nhttp://<account>.lighthouseapp.com , please try again"
      q.responses[:ask_on_error]="My lighthouse account is : "
    end
    
    puts
    puts "what token would you like to use for the account : #{config['account']} ?"
    config['token']=ask("My lighthouse token is : ") do |q|
      q.validate = /^[0-9a-f]{40}$/ 
      q.responses[:not_valid]="\nError :\nThat seems to be incorrect, we would like to have your lighthouse token\n this looks something like : 1bd25cc2bab1fc4384b7edfe48433fba5f6ee43c"
      q.responses[:ask_on_error]="My lighthouse token is : "
    end
    puts

    puts "generated your config in #{self.global_config_file}, going on with main program..."
    File.open(self.global_config_file,'w+'){ |f| f.write(YAML::dump(config)) }
    load_global_config
  end

  def load_global_config
    if File.exists? self.global_config_file
      config = YAML.load_file(self.global_config_file)
      if config && config.class==Hash && config.has_key?('account') && config.has_key?('token')
        return [config['account'], config['token']]
      else
        puts "global config did not validate , recreating"
        global_config_wizard
      end
    else
      puts "global config not found at #{self.global_config_file}, starting wizard"
      global_config_wizard
    end
  end
  
  def load_project_config
    if File.exists? self.project_config_file
      config = YAML.load_file(self.project_config_file)
      if config && config.class==Hash && config.has_key?('project_id')
        return config['project_id']
      else
        puts "project config not found"
        #todo local_config_wizard
      end
    else
      puts "project config not found at #{self.global_config_file}, starting wizard"
      #todo local_config_wizard
    end
  end
  
  
  def account
    lighthouse.account
  end
  
  def token
    lighthouse.token
  end
  
  def projects
    puts "fetching projects..."
    
    project_table = table do |t|
      t.headings = ['id', 'project name', 'public', 'open tickets']
      projects=cache.load(:name=>"projects",:action=>"Lighthouse::Project.find(:all)")
      projects.each do |project|
        t << [{:value=>project.id, :alignment=>:right}, project.name, project.public, {:value=>project.open_tickets_count, :alignment=>:right}]
      end
    end    
    puts project_table
  end
  
  def tickets
    if self.current_project_id
      tickets=cache.load(:name=>"tickets", :action=>"Lighthouse::Project.find(#{self.current_project_id}).tickets")
      tickets_table = table do |t|
        t.headings = [
          '#', 
          'state', 
          'title', 
          'tags', 
          'by', 
          'assigned to', 
          'created at', 
          'updated at'
        ]
        
        tickets.sort_by(&:number).reverse.each do |ticket|
          t << [
            {:value=>ticket.number, :alignment=>:right}, 
            {:value=>ticket.state,:alignment=>:center}, 
            ticket.title, 
            ticket.tag, 
            ticket.creator_name, 
            ticket.assigned_user_name, 
            {:value=>DateParser.string(ticket.created_at.to_s), :alignment=>:right}, 
            {:value=>DateParser.string(ticket.updated_at.to_s), :alignment=>:right}
          ]
        end
      end
      puts tickets_table
    else
      "sorry , we have no project id"
    end
  end
  
  
  
end