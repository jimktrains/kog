require 'parslet'
require 'pp'
include Parslet

class SimpleParser < Parslet::Parser
	rule(:bool)   { (true_kw | false_kw).as(:bool) >> space? }
	rule(:name)   { match('[A-Za-z0-9_?!]').repeat.as(:name) >> array_index.repeat.maybe >> space? }
	rule(:number) { match('[0-9]').repeat.as(:number) >> space? }
	rule(:space)  { match('\s').repeat }
	rule(:space?) { space.maybe }

	rule(:binary_op) { match('[&|^]') >> space? }
	rule(:binary_ex) { expression.as(:rhs) >> binary_op.as(:op) >> expression.as(:lhs) }
	rule(:binary_ex_paren) { lparen >> binary_ex >> rparen }

	rule(:cond) {
		(if_kw >> logic_atom.as(:cond) >> exec_body).as(:if) >>
		(
			else_kw >>
			exec_body.as(:if_false)
		).as(:else).maybe
	}

	rule(:lparen)  { str('(') >> space? }
	rule(:rparen)  { str(')') >> space? }
	rule(:comma)   { str(',') >> space? }
	rule(:body)    { lbrace >> expression.as(:body) >> rbrace }
	rule(:lbrace)  { str('{')    >> space? }
	rule(:rbrace)  { str('}')    >> space? }
	rule(:lbracket){ str('[')    >> space? }
	rule(:rbracket){ str(']')    >> space? }
	rule(:comma)   { str(',')    >> space? }

	rule(:if_kw)   { str('if')   >> space? }
	rule(:true_kw) { str('T') | str('True') }
	rule(:false_kw){ str('F') | str('False') }
	rule(:else_kw) { str('else') >> space? }
	rule(:func_kw) { str('Function') >> space? }
	rule(:as) { space >> str('as') >> space }
	rule(:every) { str('Every') >> space }
	rule(:enum) { str('Enum').as(:enum) >> lparen >> (name.as(:name) >> (comma >> name.as(:name)).repeat).as(:values) >> rparen }
	rule(:array_index) { lbracket >> (number|base_exec_body).as(:index) >> rbracket }
	rule(:ms_time_unit) {  str('Miliseconds') | str('Milisecond') | str('ms') }
	rule(:time_unit) { (ms_time_unit).as(:time_unit) >> space? }
	rule(:base_exec_body) { (func | cond | logic_expression_paren | funccall | assignment | foreach_section) }
	rule(:exec_body) { lbrace >> base_exec_body.repeat.as(:body)  >> rbrace }
	rule(:prog_body) { lbrace >> (base_exec_body | every_section | rescue_section | setup_section).repeat.as(:body) >> rbrace }

	rule(:rule_exp) { (name.as(:type) >> lparen >> var_list.as(:varaibles) >> rparen >> str(':') >> space >> logic_atom.as(:rule)).as(:fault) }
	rule(:rule_kw) { str('Rules') >> space? }
	rule(:colon) { str(':') >> space? }
	rule(:var_list) { name.as(:variable) >> (comma >> name.as(:variable)).repeat.maybe }
	rule(:rule_section) { rule_kw >> lbrace >> rule_exp.repeat.as(:rules) >> rbrace }

	rule(:assignment) { name.as(:object) >> space? >> str(':=').as(:op) >> space? >> ( func | logic_expression_paren | funccall).as(:value) >> space? }
	rule(:types_section) { str('Types') >> space? >> lbrace >>
		(( name.as(:name) >> as >> type_def.as(:type) >> space).repeat).as(:types) >>
		rbrace
	}

	rule(:logic_atom) { ( logic_expression_paren | name ) >> space? }

	rule(:logic_op) { (str('==') | str('<') | str('>') | str('<>') | str('<=') | str('>=') | 
	                   str('&') | str('^') | str('|') | str('->') | str('<-->')
	                  ) >> space? }
	rule(:logic_binary_expression) { logic_atom.as(:lhs) >> logic_op.as(:op) >> logic_atom.as(:rhs) }

	rule(:logic_unary) { ( str('~') ) >> space? }
	rule(:logic_unary_expression) { logic_unary.as(:op) >> logic_atom.as(:predicate) }

	rule(:logic_expression_paren) { lparen >> (logic_binary_expression|logic_unary_expression|logic_atom) >> rparen }

	rule(:stop_bits) { (match['12']).as(:stop_bit) >> str('bit') >> space >> str('Stop') }
	rule(:frame_size) { (match('[56789]')).as(:frame_size) >> str("bit") >> space >> str("Frame") }
	rule(:parity) { (str('Even') | str('Odd') | str('None')).as(:parity) >> space >> str('Parity')}
	rule(:baud) { (number).as(:baud) >> space >> str('Baud') }
	rule(:uart_dec) { (str('UART:') >> number.as(:address) >> comma >> baud >> comma >> parity >> comma >> frame_size >> comma >> stop_bits).as(:uart) }
	rule(:spi_dec) { (str('SPI:') >> (str('master')|str('slave')).as(:address)).as(:spi) }
	rule(:port_name) {  (spi_dec|uart_dec|( (name >> str(':')).maybe >> number)).as(:port) >> space?}
	rule(:input_type) { (str('Input') >> lparen >> port_name >> rparen).as(:input) }
	rule(:output_type) { (str('Output') >> lparen >> port_name >> rparen).as(:output) }
	rule(:inputoutput_type) { (str('IO') >> lparen >> port_name >> rparen).as(:IO) }
	rule(:io_type) { inputoutput_type | input_type | output_type }
	rule(:type_def) { enum| io_type | name   }
	rule(:variables_sections) { str('Variables') >> space? >> lbrace >>
		(param >> space).repeat.as(:variables) >>
		rbrace
	}
	rule(:properties_section) { str('Properties') >> space? >> lbrace >>
		(prop.repeat).as(:properties) >> 
		rbrace
	}
	rule(:program_section) { str('Program') >> space >> name.as(:program) >> space? >> prog_body.as(:body)}
	rule(:every_body) { lbrace >> (rescue_section | every_section | base_exec_body).repeat.as(:body) >> rbrace }
	rule(:every_section) { ( every >> number.as(:amount) >> time_unit >> every_body ).as(:every) }
	rule(:foreach) { str('ForEach') >> space }
	rule(:foreach_section) { (foreach >> name.as(:over) >> as >> name.as(:loop_var) >> exec_body).as(:foreach) }
	rule(:rescue_kw) { str('Rescue') >> space }
	rule(:rescue_section) { (rescue_kw >> (name.as(:inst_var) >> as >> name.as(:fault)).as(:cond) >> exec_body).as(:rescue) }
	rule(:setup_kw) { str('Setup') >> space }
	rule(:setup_section) { (setup_kw >> exec_body).as(:setup) }

	rule(:prop) { func_kw >> name.as(:prop) >> param1 >> lbrace >> logic_atom.as(:body) >> rbrace}
	rule(:func) { func_kw >> name.as(:func) >> params >> exec_body.repeat.as(:body)}

	rule(:funccall) { name.as(:funcname) >> lparen >> name.as(:name) >> (comma >> name.as(:name)).maybe.repeat >> rparen }
	rule(:param1) { lparen >> param.as(:params) >> rparen }
	rule(:param) { name.as(:param) >> as >> type_def.as(:type) }
	rule(:params) { lparen >> (param >> (comma >> param).repeat).as(:params) >> rparen }

	rule(:root) { space? >> types_section >> variables_sections >> properties_section >> rule_section >> program_section.repeat }
end

p = SimpleParser.new
tree = p.parse File.open(ARGV[0]).read
pp tree
