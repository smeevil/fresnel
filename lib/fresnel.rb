require File.dirname(Pathname.new(__FILE__).realpath) + "/lighthouse"
require File.dirname(Pathname.new(__FILE__).realpath) + "/date_parser"
require File.dirname(Pathname.new(__FILE__).realpath) + "/cache"
require File.dirname(Pathname.new(__FILE__).realpath) + "/color"
require File.dirname(Pathname.new(__FILE__).realpath) + "/setup_wizard"



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
    @cache=Cache.new(:active=>options[:cache]||false, :timeout=>options[:cache_timeout]||5.minutes)
    Lighthouse.account, Lighthouse.token = load_global_config
    @current_project_id=load_project_config
  end

  def load_global_config
    if File.exists? self.global_config_file
      config = YAML.load_file(self.global_config_file)
      if config && config.class==Hash && config.has_key?('account') && config.has_key?('token')
        return [config['account'], config['token']]
      else
        puts "global config did not validate , recreating"
        SetupWizard.global(self)
        load_global_config    
      end
    else
      puts "global config not found at #{self.global_config_file}, starting wizard"
      SetupWizard.global(self)
      load_global_config    
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
      SetupWizard.project(self)
      load_project_config
    end
  end

  def account
    lighthouse.account
  end

  def token
    lighthouse.token
  end

  def projects(options=Hash.new)
    options[:object]||=false
    puts "fetching projects..."
    
    projects_data=cache.load(:name=>"projects",:action=>"Lighthouse::Project.find(:all)")
    project_table = table do |t|
      t.headings = ['id', 'project name', 'public', 'open tickets']
      
      projects_data.each do |project|
        t << [{:value=>project.id, :alignment=>:right}, project.name, project.public, {:value=>project.open_tickets_count, :alignment=>:right}]
      end
    end
    options[:object] ? projects_data : puts(project_table)
  end

  def tickets
    if self.current_project_id
      tickets=cache.load(:name=>"project_#{self.current_project_id}_tickets", :action=>"Lighthouse::Project.find(#{self.current_project_id}).tickets")
      if tickets.any?
        tickets_table = table do |t|
          t.headings = [
            {:value=>'#',:alignment=>:center},
            {:value=>'state',:alignment=>:center},
            {:value=>Color.print('title'),:alignment=>:center},
            {:value=>Color.print('tags'),:alignment=>:center},
            {:value=>'by',:alignment=>:center},
            {:value=>'assigned to',:alignment=>:center},
            'created at',
            'updated at'
          ]

          tickets.sort_by(&:number).reverse.each do |ticket|
            t << [
              {:value=>ticket.number, :alignment=>:right},
              {:value=>ticket.state,:alignment=>:center},
              Color.print("#{ticket.title.strip[0..50]}#{"..." if ticket.title.size>50}",ticket.tag),
              Color.print(ticket.tag,ticket.tag),
              ticket.creator_name,
              ticket.assigned_user_name,
              {:value=>DateParser.string(ticket.created_at.to_s), :alignment=>:right},
              {:value=>DateParser.string(ticket.updated_at.to_s), :alignment=>:right}
            ]
          end
        end
        puts tickets_table
      else
        puts "no tickets found yet..."
      end
    else
      "sorry , we have no project id"
    end
  end

  def show_ticket(number)
    
    ticket = cache.load(:name=>"ticket_#{number}",:action=>"Lighthouse::Ticket.find(#{number}, :params => { :project_id => #{self.current_project_id} })")
    puts
    
    ticket_output=Array.new
    ticket_output<<"+----------------------------------------------------------------------------------------------------------------+"
    ticket_output<< "Ticket ##{number} : #{ticket.title}"
    ticket_output<< "Date : #{DateParser.string(ticket.created_at.to_s)} by #{ticket.creator_name}"
    ticket_output<< "Tags : #{ticket.tag}"
    ticket_output<< "+----------------------------------------------------------------------------------------------------------------+"
    ticket_output<< ""
    ticket_output+=ticket.versions.first.body.gsub(/\t/,"     ").gsub(/.{1,110}(?:\s|\Z)/){($& + 5.chr).gsub(/\n\005/,"\n").gsub(/\005/,"\n")}.split("\n")
    ticket_output<< ""
    ticket_output<< "+----------------------------------------------------------------------------------------------------------------+"
    ticket_output.each do |l|
      puts "#{" |" unless l=~/^\+/} #{l.ljust(110)} #{"|" unless l=~/^\+/}"
    end
    puts

    ticket.versions.each do |v|
      next if v.created_at==ticket.versions.first.body
      if v.body.nil?
        puts "  State changed on #{DateParser.string(v.created_at.to_s)} to : #{v.state} by #{v.creator_name}"
      else
        puts
        ticket_output=Array.new
        ticket_output<<"+----------------------------------------------------------------------------------------------------------------+"
        str=v.creator_name.capitalize
        date=DateParser.string(v.created_at.to_s)
        str=str.ljust(110-date.size)
        str+=date
        ticket_output<<str
        ticket_output<< "+----------------------------------------------------------------------------------------------------------------+"        
        ticket_output<< ""
        ticket_output+=v.body.gsub(/\t/,"     ").gsub(/.{1,110}(?:\s|\Z)/){($& + 5.chr).gsub(/\n\005/,"\n").gsub(/\005/,"\n")}.split("\n")
        ticket_output<< ""
        ticket_output<< "+----------------------------------------------------------------------------------------------------------------+"
        ticket_output.each do |l|
          puts "#{" |" unless l=~/^\+/} #{l.ljust(110)} #{"|" unless l=~/^\+/}"
        end
        puts
      end
    end
  end

end