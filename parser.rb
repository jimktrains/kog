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

	#rule(:expression) { cond | funcall | number | name | bool | binary_ex | binary_ex_paren }
	rule(:expression) {  bool | binary_ex_paren | binary_ex | name | number | funcall }


	rule(:cond) {
		(if_kw >> logic_atom.as(:cond) >> exec_body).as(:if) >>
		(
			else_kw >>
			body.as(:if_false)
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
	rule(:func_kw) { str('function') >> space? }
	rule(:as) { space >> str('as') >> space }
	rule(:every) { str('Every') >> space }
	rule(:enum) { str('Enum').as(:enum) >> lparen >> (name.as(:name) >> (comma >> name.as(:name)).repeat).as(:values) >> rparen }
	rule(:array_index) { lbracket >> (number|expression).as(:index) >> rbracket }
	rule(:ms_time_unit) {  str('Miliseconds') | str('Milisecond') | str('ms') }
	rule(:time_unit) { (ms_time_unit).as(:time_unit) >> space? }
	rule(:base_exec_body) { (func | cond | logic_expression_paren | funccall | assignment | foreach_section) }
	rule(:exec_body) { lbrace >> base_exec_body.repeat.as(:body)  >> rbrace }
	rule(:prog_body) { lbrace >> (base_exec_body | every_section | rescue_section | setup_section).repeat.as(:body) >> rbrace }

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

	rule(:type_def) { enum | name  }
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

	rule(:root) { space? >> types_section >> variables_sections >> properties_section >> program_section.repeat }
end

p = SimpleParser.new
tree = p.parse <<EOS
Types {
	Phase as Integer[2]
	Indicator as Bool
	Color as Enum(Red, Yellow, Green)
	Head as Indicator[3]
}

Variables {
	North as Head
	South as Head
	East as Head
	West as Head

	CurrentPhase as Phase
	Alternate as Bool
	Counter as Integer
}

Properties {
	function IsRed(X as Head)    { ( (X[0]) & ( (~X[1]) & (~X[2]))) }
	function IsYellow(X as Head) { ((~X[0]) & ( ( X[1]) & (~X[2]))) }
	function IsGreen(X as Head)  { ((~X[0]) & ( (~X[1]) & ( X[2]))) }
	function IsClear(X as Head)  { ((~X[0]) & ( (~X[1]) & (~X[2]))) }
}

Program Main {
	function SetHead(h as Head, c as Color) { 
		X[0] := (c == Red)
		X[1] := (c == Yellow)
		X[2] := (c == Green)
	}

	Setup {
		X[0] := (True)
		X[1] := (False)
		X[2] := (False)
	}

	function ClearHead(h as Head) {
		X[0] := (False)
		X[1] := (False)
		X[2] := (False)
	}

	Every 5 Miliseconds {
		if (A) {
			ForEach X as ind {
			}
		}
		Rescue f as TimeConstraintViolated {
		}
	}
	Rescue f as PhaseConflict {
	}
	Rescue f as TimeConstraintViolated {
	}
}

Program Conflict {}

EOS

pp tree
