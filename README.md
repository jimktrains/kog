# Kog

This language is designed to aid in the programming of Real-Time systems, specifically memory-constrained microcontrollers.

My goals are to make it strongly types, easy to use and verify, as well as supporting a decent object system.

See [small.kog](small.kog) for an idea of what I want it to become.  parser.py is slightly out of date and won't currently parse small.kog

## Syntax

### Identifiers

#### Variables

These are variables and can be assigned to.

A-Za-z0-9_

#### Symbol

These are symbles and cannot be assgined to.

: follow by A-Za-z0-9+-^&'

### Types

#### Base

These are predefined Objects in the system

* Integer
* String

#### Builders

These types that are used to define new types

* Object
* Enum
* Set
* Tuple
* Method
 * Function
 * Table

### Table
Tables are used to define table look-ups in an æsthetic manner.

A Table has 2 parts

* Header - Defines the types in the table.  The lookup section must be an Enum and cover all values for that Enum.  Each lookup-type is separated by a double bar (|).  The Lookup section is separated from the return types by a double bar (||).  The following line may only consist of dash (-) and pluses (+). Spacing in the header doesn't affect meaning and may be changed in order to make the table look good. The return types are separated by a bar (|)
* Data - Contains all of the lookup values and their associated return values.  Like the header, the lookup values are separated by bars(|) and from the return values by a double bar(||). The sections may or may not be separated by a spacing line similar to the one below the header.  The table may or may not end in a spacing line.

Tables are used by VarName((Lookup1, Lookup2)) There are 2 parenthesis becase the parameter is a tuple. Since the table returns a tuple, they can be used as input to another table lookup. TableName(Table2Name((Lookup1, Lookup2)))

	Enum1    | Enum2    || Type1    | Type2
	---------+----------++----------+---------
	Lookup11 | Loopup21 || Return11 | Return21
	Lookup12 | Loopup22 || Return12 | Return22

### Sets
Sets can be used as type and creates an Enum of the given values. The values retain their own type, and the set can be used as most specific common type of all the values in the set. The following snippet shows an example

	Types
		Odds as Set(1,3,5,7,9)
	Variables
		Example as Odds
		Example2 as Odds
		Num as Integer
	Program Main
		Example := 1
		Example2 := 3
		Num := Example + 2
		Example := Example2
		Example := Num # This is not allowed as it cannot be guaranteed  at compile time to be valid
		Example := Example + 2 # ditto

# Sections

* Object
 * Variables
 * Setup
 * Methods
 * Properties
 * Rules
* Enum
* Set
* Program
 * Variables
 * Setup
 * Methods
 * Properties
 * Rules
 * Body

## Goals

To be able to compile programs that can be run on microcontrollers.
