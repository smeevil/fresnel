class InputDetector
  attr_accessor :question, :possible_answers, :collection, :answer
  
  def initialize(question,*answers)
    @question=question
    @possible_answers=Array.new
    @possible_answers+=question.scan(/\[(.*?)\]/).flatten
    @possible_answers+=answers.flatten
    @collection=""
    @answer=""
    print question
    detect_answer
  end
  
  def detect_answer
    loop do
      begin
        system("stty raw -echo")
        str = STDIN.getc
      ensure
        system("stty -raw echo")
      end
      print str.chr
      if str == 13
        exit if collection.blank?
        possible_options = possible_answers.select{|option| option == collection}
      else
        self.collection+=str.chr
        possible_options = possible_answers.select{|option| option.to_s =~ /^#{collection}/}
      end
      if possible_options.size == 0
        if str==3
          puts
          puts "exiting due to ^c"
          exit 
        end
        puts
        puts "Invalid choice: #{collection}, choises are #{possible_answers.inspect}"
        print question
        self.collection=""
      elsif possible_options.size == 1
        collection = possible_options.first
        self.answer=collection.to_s
        puts
        break
      else
        next
      end
    end
  end
end
