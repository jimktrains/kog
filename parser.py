# indentedGrammarExample.py
#
# Copyright (c) 2006, Paul McGuire
#
# A sample of a pyparsing grammar using indentation for 
# grouping (like Python does).
#

from pyparsing import *
import sys

indentStack = [1]

def checkPeerIndent(s,l,t):
    curCol = col(l,s)
    if curCol != indentStack[-1]:
        if (not indentStack) or curCol > indentStack[-1]:
            raise ParseFatalException(s,l,"illegal nesting")
        raise ParseException(s,l,"not a peer entry")

def checkSubIndent(s,l,t):
    curCol = col(l,s)
    if curCol > indentStack[-1]:
        indentStack.append( curCol )
    else:
        raise ParseException(s,l,"not a subentry")

def checkUnindent(s,l,t):
    if l >= len(s): return
    curCol = col(l,s)
    if not(curCol < indentStack[-1] and curCol <= indentStack[-2]):
        raise ParseException(s,l,"not an unindent")

def doUnindent():
    indentStack.pop()
    
INDENT = lineEnd.suppress() + empty + empty.copy().setParseAction(checkSubIndent)
UNDENT = FollowedBy(empty).setParseAction(checkUnindent)
UNDENT.setParseAction(doUnindent)

stmt = Forward()
suite = Group( OneOrMore( empty + stmt.setParseAction( checkPeerIndent ) )  )
identifier = Word(alphas, alphanums + '_')

type_spec = oneOf("Integer Boolean")

rvalue = Forward()
funcCall = Group(identifier + "(" + Optional(delimitedList(rvalue)) + ")")
rvalue << (funcCall | identifier | Word(nums))


VARIABLES, PROGRAM, AS, INTEGER, PRINT, IF, ELSE, TRUE, FALSE, BOOLEAN = map(
    CaselessKeyword,
    [ "VARIABLES",
      "PROGRAM",
      "AS",
      "INTEGER",
      "PRINT",
      "IF",
      "ELSE",
      "TRUE",
      "FALSE",
      "BOOLEAN"
    ])
keyword = MatchFirst([VARIABLES, PROGRAM, AS, INTEGER, PRINT, IF, ELSE, TRUE, FALSE, BOOLEAN])

typeSpecifier = INTEGER | BOOLEAN

number = Word(nums)
bools = TRUE | FALSE
ident = ~keyword + Word(alphas, alphanums+'_')
operand = funcCall | number | identifier | bools

expr = operatorPrecedence(operand,
    [
    ('-', 1, opAssoc.RIGHT),
    (oneOf('* /'), 2, opAssoc.LEFT),
    (oneOf('+ -'), 2, opAssoc.LEFT),
    ])

comparisonExpr = operatorPrecedence(operand,
    [
    (oneOf("< > == <= >= !="), 2, opAssoc.LEFT),
    ])
booleanExpr = operatorPrecedence(comparisonExpr,
    [
    ('~', 1, opAssoc.RIGHT),
    (oneOf('& | ^'), 2, opAssoc.LEFT),
    ])

var_dec = (identifier + "as" + identifier)
prop_list = Group( "(" + Optional( delimitedList(var_dec) ) + ")" )

var_dec_suite = Group( OneOrMore( empty + var_dec.copy().setParseAction( checkPeerIndent ) )  )
var_sec = Group( 'Variables' + INDENT + var_dec_suite + UNDENT )

prop_dec = (identifier + prop_list + booleanExpr)
prop_dec_suite = Group( OneOrMore( empty + prop_dec.setParseAction( checkPeerIndent ) )  )
prop_sec = Group( 'Properties' + INDENT + prop_dec_suite + UNDENT )

rule_dec = ( Group( "(" + Optional( delimitedList(identifier) ) + ")" ) + "causes" + identifier + "when" + booleanExpr)
rule_dec_suite = Group( OneOrMore( empty + rule_dec.setParseAction( checkPeerIndent ) )  )
rule_sec = Group( 'Rules' + INDENT + rule_dec_suite + UNDENT )

funcDecl = ("def" + identifier + prop_list + ':')
funcDef = Group( funcDecl + INDENT + suite + UNDENT )

assignment = Group(identifier + ":=" + rvalue)

stmt.ignore('#' + restOfLine)
stmt << ( var_sec | prop_sec | rule_sec | funcDef | assignment | identifier)


data = None
with open(sys.argv[1], 'r') as f:
    data = f.read()

parseTree = suite.parseString(data)

import pprint
pprint.pprint( parseTree.asList() )
