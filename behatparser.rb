require 'cgi'
require 'optparse'

class BehatEntity
  def get_id
	begin
		@id=(0...10).map{ ('a'..'z').to_a[rand(26)] }.join
	end if @id==nil
	@id
  end
  
  def self.strip_path(full_path)
	full_path=~/.*\\([^\\]*)/
	$1
  end
  
  def self.to_html_table_tfoot
	""
  end

end

class BehatStep < BehatEntity
  
  include Comparable

  attr :behat_step
  
  BEHAT_STEP_REGEX=/^.*(Given|When|Then).*\/\^(.*)\$\/$/
  
  def <=>(other)
    @behat_step <=> other.behat_step
  end
  
  def initialize(disk_loc, behat_regex, function_spec, step_line_number)
    @disk_loc=disk_loc
    @behat_regex=behat_regex
    @function_spec=function_spec
    @step_line_number=step_line_number
    @used_in_scenarious=[]
	
    process_inputs
  end
  
  def process_inputs
    
    #get the step definition out of the step
    @behat_regex=~BEHAT_STEP_REGEX
    
    @behat_adverb=$1
    @behat_step=$2
    
  end
  
  #takes in a line and check if the line is call to this step
  def is_in_feature(file_location, line_num, line)
	if line=~/#{@behat_step}/
		@used_in_scenarious.push({:file_location => file_location, :line_num => line_num})
		return true
	end
	return false
  end
  
  def self.get_behat_step_regex
	BEHAT_STEP_REGEX
  end
  
  def to_s
    "#{@disk_loc} #{@behat_regex} #{@function_spec}"
  end
  
  #returns a div containing all features using this step
  def to_list_of_features
	features=""
	@used_in_scenarious.each do |usage|
	 features+="#{BehatStep.strip_path(usage[:file_location])}:#{usage[:line_num]}<br>"
	end
	
	"<div id=\"#{self.get_id}\" style=\"display: none;\" title=\"#{CGI.escapeHTML(@behat_regex)}\"><p>#{features}</p></div>"
  end
  
  #
  def to_html_table_row
    result="<tr>"
    result+="<td><a id=\"#{self.get_id}-anchor\">#{BehatStep.strip_path(@disk_loc)}:#{@step_line_number}</a></td>"
    result+="<td>#{@behat_adverb}</td>"
    result+="<td>#{@behat_step} </td>"
    result+="<td>#{@function_spec} </td>"
	#result+="<td><a href=\"#\" onClick=\" $('##{self.get_id}').dialog() \">#{@used_in_scenarious.size}</a></td>"
	result+="<td><a href=\"##{self.get_id}-anchor\" onClick=\" showUsages('##{self.get_id}') \">#{@used_in_scenarious.size}</a></td>"
    result+="</tr>"
  end
  
  def self.html_table_thead
    result="<th>Disk Location</th>"
    result+="<th>Behat adverb</th>"
    result+="<th>Behat rejex</th>"
    result+="<th>Function</th>"
	result+="<th>Num Features</th>"
  end
  
  def self.html_static_to_head
	result="<script>function showUsages(div_id)
			{
				$(div_id).dialog({width:900, height:500, position:{ my: \"top\", at: \"top\", of: div_id+'-anchor' }})
			}
			</script>
			"
  
  end
end

class BehatStepsParser
  
  class ParserStateMachine
    def initialize(steps_array, file_location)
      @current_state=:not_in_step
      @in_step_line_counter=0
      @steps_array=steps_array
      @file_location=file_location
    end
    
    def next(line, line_number)
      
      line_status=BehatStepsParser.identify_line(line)
      
      @in_step_line_counter+=1
      
      return if line_status==:unknown
      
      if line_status==:behat_regex
        @in_step_line_counter=0
        @current_state=:in_step
        @last_behat_regex=line
        @first_identified_line_number=line_number
      end
      
      if line_status==:function_spec
        #if we are not in step its just a function that we don't care about
        return unless @current_state==:in_step
        line_counter=@in_step_line_counter
        @in_step_line_counter=0
        
        # if there were a lot of lines between the behat regex and function defition, somethins is wrong
        begin
          @current_state=:not_in_step
          return
        end if line_counter>2 
        
        #create a new step
        @steps_array.push(BehatStep.new(@file_location, @last_behat_regex, line, @first_identified_line_number))
        @current_state=:not_in_step
      end
      
    end
  end
  
  
  def self.identify_line(line)
    return :behat_regex if line=~BehatStep.get_behat_step_regex
    return :function_spec if line=~/^\s*public function.*$/
    return :unknown
  end
  
  def self.parse_file(file_location, steps_array)
    num=0
    parser_state_machine=ParserStateMachine.new(steps_array, file_location)
    File.open( file_location ).each do |line|
      num+=1
      parser_state_machine.next(line, num)
    end
  end
end

class BehatScenario < BehatEntity

	BEHAT_SCENARIO_REGEX=/^Scenario:(.*)$/

	@@tag_names={}
	@@disk_locations={}

	def initialize(disk_location, line_num, scenario, tags)
		@disk_location=disk_location
		@scenario=scenario
		@line_num=line_num
		@tags=[]
		parse_tags(tags)
		
		@@disk_locations[disk_location]=0 unless @@disk_locations.key?(disk_location)
		@@disk_locations[disk_location]+=1
	end

	def parse_tags(tags)
		#check if the line starts with @
		return unless tags=~/^@.*$/
	
		tags.split(' ').each do |tag|
		
			#add a tag unless it matches an exclusion
			begin
				#check if tag is already in the static array
				@@tag_names[tag]=0 unless @@tag_names.key?(tag)
				@@tag_names[tag]+=1
				@tags.push(tag)
			end unless tag=~/RFDO/
		
			@tags.push(tag)
		end
	end
	
	def to_html_table_row
		result="<tr>"
		result+="<td><a id=\"#{self.get_id}-anchor\">#{BehatStep.strip_path(@disk_location)}:#{@line_num} [#{@@disk_locations[@disk_location]}]</a></td>"
		result+="<td>#{@scenario}</td>"
		@@tag_names.keys.each do |tag_name|
			tag_value="_"
			tag_value="Y" if @tags.include?(tag_name)
			result+="<td>#{tag_value}</td>"
		end
		result+="</tr>"
	end
	
	def self.html_table_thead
		result="<th>Disk Location</th>"
		result+="<th>Scenario</th>"
		@@tag_names.keys.sort.each do |tag_name|
			result+="<th>#{tag_name} .</th>"
		end
		result
	end
	
	def self.to_html_table_tfoot
		result="<tr>"
		result+="<td>Totals</td>"
		result+="<td></td>"
		@@tag_names.keys.sort.each do |tag_name|
			result+="<td>#{@@tag_names[tag_name].to_s}</td>"
		end
		result+="</tr>"
	end
	
	def self.get_scenario(line)
		return $1 if line=~BEHAT_SCENARIO_REGEX
		nil
	end
end

class BehatFeaturesParser

  def self.parse_file(file_location, steps_array, scenarios_array)
    
	prev_line=""
	
	num=0
    File.open( file_location ).each do |line|
      num+=1
	  
	  steps_array.each do |step|
		break if step.is_in_feature(file_location, num, line)
	  end
	  
	  scenario=BehatScenario.get_scenario(line)
	  
	  scenarios_array.push(BehatScenario.new(file_location, num, scenario, prev_line)) if scenario
	  
	  prev_line=line
	end
  end
end

def print_table(myfile, behat_entity_class, entities_array, table_id)
	myfile.puts "<table id=\"#{table_id}\" class=\"tablesorter\" border=\"1\">"
	myfile.puts "<thead>"
	myfile.puts behat_entity_class.html_table_thead
	myfile.puts "</thead>"
	myfile.puts "<tbody>"
	entities_array.each do |entity|
	  myfile.puts entity.to_html_table_row
	end
	myfile.puts "</tbody>"
	myfile.puts "<tfoot>"
	myfile.puts behat_entity_class.html_table_thead
	myfile.puts behat_entity_class.to_html_table_tfoot
	myfile.puts "</tfoot>"
	myfile.puts "</table>"
end


if __FILE__ == $0

	options = {}
	op = OptionParser.new do |opts|
	  opts.banner = "Usage: behatparser.rb [options]"

	  opts.on('-i', '--input inputpath', 'Path to features folder') { |v| options[:input_path] = v }
	  opts.on('-o', '--output outputfile', 'Name of the output file') { |v| options[:output_path] = v }
	  opts.on('-h', '--help', 'Display this screen' ) do
		puts opts
		exit
	  end

	end

	op.parse!

	#make sure we get the two parameters passed in
	begin 
		puts op.help
		exit
	end if !options[:input_path] || !options[:output_path]

	input_path=options[:input_path]
	
	output_path=options[:output_path]

	input_path+='\\' unless input_path=~/\\$/
	bootstrap_input_path="#{input_path}bootstrap\\"

	steps=[]
	scenarios=[]

	Dir.foreach(bootstrap_input_path) do |f|
		BehatStepsParser.parse_file(bootstrap_input_path+f, steps) if f=~/\.php$/i
	end

	Dir.foreach(input_path) do |f|
		BehatFeaturesParser.parse_file(input_path+f, steps, scenarios) if f=~/\.feature$/i
	end

	#sort the steps
	steps.sort!

	#put everything into a file
	myfile = File.new(output_path, "w+") 
	myfile.puts "<html>"
	myfile.puts "<head>"
	myfile.puts "<title>Behat steps for #{input_path}</title>"

	myfile.puts '<link rel="stylesheet" href="http://code.jquery.com/ui/1.10.3/themes/smoothness/jquery-ui.css" />'
	myfile.puts '<script src="http://code.jquery.com/jquery-1.9.1.js"></script>'
	myfile.puts '<script src="http://code.jquery.com/ui/1.10.3/jquery-ui.js"></script>'
	myfile.puts '<link rel="stylesheet" href="http://jqueryui.com/jquery-wp-content/themes/jqueryui.com/style.css">'
	myfile.puts '<link rel="stylesheet" href="themes/blue/style.css" type="text/css" id="" media="print, projection, screen" />'
	myfile.puts '<script src="js/jquery.tablesorter.js"></script>'
	myfile.puts '<link rel="stylesheet" href="http://code.jquery.com/ui/1.10.3/themes/smoothness/jquery-ui.css" />'

	myfile.puts "
	<script>

	$(document).ready(function() 
	{ 
		$(\"#stepstbl\").tablesorter(); 
		$(\"#scenariostbl\").tablesorter(); 

	} 
	); 

	</script>
	"

	myfile.puts BehatStep.html_static_to_head

	myfile.puts "</head>"
	myfile.puts "<body>"

	myfile.puts "<div id=\"main\">"
	myfile.puts "<h1 title=\"Tooltip\">Output for #{input_path}</h1>"
	
	myfile.puts "<h2>Steps</h2>"
	print_table(myfile, BehatStep, steps, "stepstbl") 
	
	myfile.puts "<h2>Scenarios</h2>"
	print_table(myfile, BehatScenario, scenarios, "scenariostbl") 
	
	steps.each do |step|
	  myfile.puts step.to_list_of_features
	end

	myfile.puts "</div>"

	myfile.puts "</body>"
	myfile.puts "</html>"
  
end