class Cli
  def initialize(argv)
    @argv = argv
    @fresnel = Fresnel.new(:cache=>CACHE, :cache_timeout=>CACHE_TIMEOUT)
  end
  
  def run!
    case @argv[0]
      when "projects"
        @fresnel.projects
      when "tickets"
        @fresnel.tickets
      when "bins"
        @fresnel.get_bins
      when "create"
        @fresnel.create
      when "help"
        puts help
      when /\d+/
        if @argv[1]
          case @argv[1]
            when "comment"
              @fresnel.comment(@argv[0])
            when /^(open|closed?|hold|resolved|invalid)$/
              @fresnel.change_state(:ticket=>@argv[0],:state=>@argv[1])
            when "online"
              @fresnel.open_browser_for_ticket(@argv[0])
            when "assign"
              @fresnel.assign(:ticket=>@argv[0])
            when "claim"
              @fresnel.claim(:ticket=>@argv[0])
            else
              puts Frame.new(:header=>"Notice",:body=>"not sure what to do for #{@argv[1]}")
          end
        else
          @fresnel.show_ticket(@argv[0])
        end
      else
        @fresnel.tickets
        #puts Frame.new(:header=>"Notice",:body=>"not sure what to do for #{@argv[0]}")
    end
  end
  
  private
  
  def help
    help = {
      'projects' => 'Show all projects',
      'tickets' => 'Show all tickets',
      'bins' => 'Show all ticket bins',
      'create' => 'Create a ticket',
      'help' => 'This screen',
      '<id>' => {
        '' => 'Show ticket details',
        'comment' => 'Show comments for ticket',
        '[open|closed|hold|resolved|invalid]' => 'Change ticket state',
        'online' => 'Open browser for ticket',
        'assign' => 'Assign ticket to another user',
        'claim' => 'Claim ticket for yourself'
      }
    }
    help_lines = []
    help.each {|k,v|
      if v.kind_of?(Hash)
        v.each do |hk, hv|
          help_lines << [(k + ' ' + hk), hv]
        end
      else
        help_lines << [k, v]
      end
    }
    longest_key = help_lines.map{|line| line.first.size}.max
    help_lines.map {|line| "fresnel #{line.first}#{" "*(longest_key - line.first.size)}   #{line.last}"}.join("\n")
  end
end