# Kog

This language is designed to aid in the programming of Real-Time systems, specifically memory-constrained microcontrollers.

My goals are to make it strongly types, easy to use and verify, as well as supporting a decent object system.

See [small.kog](small.kog) for an idea of what I want it to become.  parser.py is slightly out of date and won't currently parse small.kog

## Syntax

### Units

A unit is a "typed" number. The base unit is defined, and then derived units can be derived from it.  Any unit can be used as a type when defining a varaible

	Units
		msec
			sec as 1000 msec
		inch
			foot as 12 inch
			yard as 36 inch
			mile as 5280 foot

In order to avoid using floating points, each variable defined should contain an Integer for each derived unit (meaning derived units should be below 16k of the unit their based on)

### Identifiers

#### Variables

These are variables and can be assigned to.

A-Za-z0-9_

#### Symbol

These are symbols and cannot be assigned to.

: follow by A-Za-z0-9+-^&'

### Types

#### Base

These are predefined Objects in the system

* Integer (Should be autoboxed to a 16-byte int for performance)
* Byte (Should be autoboxed to a 8-byte int for performance)
 * String

#### Builders

These types that are used to define new types

* Object
* Enum
 * Boolean
* Set
* Tuple
* Method
 * Function
 * Table
* Array

### Table
Tables are used to define table look-ups in an æsthetic manner.

A Table has 2 parts

* Header - Defines the types in the table.  The lookup section must be an Enum and cover all values for that Enum.  Each lookup-type is separated by a double bar (|).  The Lookup section is separated from the return types by a double bar (||).  The following line may only consist of dash (-) and pluses (+). Spacing in the header doesn't affect meaning and may be changed in order to make the table look good. The return types are separated by a bar (|)
* Data - Contains all of the lookup values and their associated return values.  Like the header, the lookup values are separated by bars(|) and from the return values by a double bar(||). The sections may or may not be separated by a spacing line similar to the one below the header.  The table may or may not end in a spacing line.

Tables are used by VarName((Lookup1, Lookup2)) There are 2 parenthesis becase the parameter is a tuple. Since the table returns a tuple, they can be used as input to another table lookup. TableName(Table2Name((Lookup1, Lookup2)))

	Methods
		Enum1 as Enum(:Lookup11, :Lookup12)
		Enum2 as Enum(:Loopup21, :Loopup22)
		Type1 as Enum(:Return11, :Return12)
		Type2 as Enum(:Return21, :Return22)

		MyTable as Table
			Enum1     | Enum2     || Type1     | Type2
			----------+-----------++-----------+----------
			:Lookup11 | :Loopup21 || :Return11 | :Return21
			:Lookup12 | :Loopup22 || :Return12 | :Return22
	Variables
		RetValue as (Type1, Type2)
	Body
		RetValue := Table((:Lookup11, :Loopup21)) # RetVal == (:Return11, :Return12)

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

## Arrays
Arrays are defined by supplying an array size in the type definition.

	MyList as Integer[5]

Functions that take the base type of the array (Integer in the above example), may take an array of the base type and will return an array of the function return type and same size as the input array.

	Methods
		Square(x as Integer) as Integer
			Return x*x
	Variables
		MyList as Integer[5]
	Setup
		MyList := [1,2,3,4,5]
	Body
		MyList[0] := 6 # [6,2,3,4,5]
		MyList[5] := 7 # Syntax error
		MyList := Square(MyList) # [36,4,9,16,25]

# Sections

* Object
 * Variables
 * Setup
 * Methods
 * Properties
 * Rules
 * Aliases
 * Extends
* Enum
 * Extends
 * Values
* Set
 * Extends
 * Values
* Program
 * Variables
 * Setup
 * Methods
 * Properties
 * Rules
 * Body
 * Alases

## Properties
These are methods but can only have a body of a single boolean expression which may only call other properties

	Properties
		SamePhase(p1 as Phase, p2 as Phase)
			p1 == p2

## Rules 
These are constraints to what values can assigned to varaibles. These are defined by boolean expression which may only call properties. When the condition is met, the exception in the definition is raised.

	Rules
		(Phase1, Phase2) causes ConflictFault when
			Phase1 == Phase2
		(Phase1, Phase3) causes ConflictFault when
			SamePhase(Phase1, Phase3)
# Flow Control

## If
## Every

Runs the block every given units of time.  The compiler should try to figure out how long the block will take assuming every non-mutually-exclusive (if vs else) is executed.  If it will take too long, the compiler should complain. The largest value should be on the outside.

	Every 10 msec
		x := x + 1

Nested example

	Every 100 msec
		Every 4 msec
			x := x + 1
		x := x + 1
		Every 25 msec
			x := x + 1
		Every 10 msec
			x := x + 1
			Every 5 msec
				x := x + 1

Nesting in this manner forces the programmer to define the order that the blocks will run in when both should be executing at the same time.

## Rescue

Catches exceptions

	Rescue x as ConflictFault
		x := x + 1
