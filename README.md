# Kog

This language is designed to aid in the programming of Real-Time systems, specifically memory-constrained microcontrollers.

My goals are to make it strongly types, easy to use and verify, as well as supporting a decent object system.

One design thought going into this language is to avoid, ideally all, dynamic memory manamgment.  The more that can be done at compile time the better.

See [small.kog](small.kog) for an idea of what I want it to become.  parser.py is slightly out of date and won't currently parse small.kog

## Syntax

### Units

A unit is a "typed" number. The base unit is defined, and then derived units can be derived from it.  Any unit can be used as a type when defining a varaible

	Units
		usec
			msec as 1000 usec
			sec as 1000 msec
		inch
			foot as 12 inch
			yard as 36 inch
			mile as 5280 foot

In order to avoid using floating points, each variable defined should contain an Integer for each derived unit (meaning derived units should be below 16k of the unit their based on)

### Identifiers

#### Variables

These are variables and can be assigned to.

	[A-Za-z0-9_]+

#### Symbol

These are symbols and cannot be assigned to.

	:[A-Za-z0-9+-^&']+

### Types

#### Base

These are predefined Objects in the system

* Integer (Should be autoboxed to a 16-byte int for performance) (Since the main purpose of this language is microcontrollers, I'm not including a floating-point or large int type. There isn't any reason a floating point type couldn't be added for machines that support it.)
* Fixed - Q16.16 fixed point decimal
* Byte - (Should be autoboxed to a 8-byte int for performance)
 * String
* IO
 * IOPin(x)
 * InPin(x)
 * OutPin(x)
 * UART(x, y Baud, Even/Odd Parity, zbit Frame, abit Stop)
 * SPI(:Master)
 * SPI(:Slave)
 * I2C

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

### Methods

Methods are blocks of code that are named and whos inputs and outputs are typed

The ``Return`` keyword is used to return a from the method and exit the method.

	Methods
		Square(x as Integer) as Integer
			Return x*x

#### Currying

A method called with fewer than the number of arguments will result in a method being returned with the rest of the arguments from the original as arguments.

	Methods
		Multiply(x as Integer, y as Integer) as Integer
			Return x * y
	Variables
		Double as Method(x as Integer) as Integer
		RetVal as Integer
	Body
		Double := Multiply(2)
		RetVal := Double(3) # RetVal == 6

### Table
Tables are used to define table look-ups in an æsthetic manner.

A Table has 2 parts

* Header - Defines the types in the table.  The lookup section must be an Enum and cover all values for that Enum.  Each lookup-type is separated by a double bar (|).  The Lookup section is separated from the return types by a double bar (||).  The following line may only consist of dash (-) and pluses (+). Spacing in the header doesn't affect meaning and may be changed in order to make the table look good. The return types are separated by a bar (|)
* Data - Contains all of the lookup values and their associated return values.  Like the header, the lookup values are separated by bars(|) and from the return values by a double bar(||). The sections may or may not be separated by a spacing line similar to the one below the header.  The table may or may not end in a spacing line.

Tables are used by VarName((Lookup1, Lookup2)) There are 2 parenthesis becase the parameter is a tuple. Since the table returns a tuple, they can be used as input to another table lookup. TableName(Table2Name((Lookup1, Lookup2)))

	Types
		Enum1 as Enum(:Lookup11, :Lookup12)
		Enum2 as Enum(:Loopup21, :Loopup22)
		Type1 as Enum(:Return11, :Return12)
		Type2 as Enum(:Return21, :Return22)

	Methods
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

There is a special array type ``Statistical``.  This can be used with the statistical methods. Additional information is stored alongside the array to aid in efficent calulations of statistical properties.

	Variables
		MyList as Statistical as Integer[10]
	Body
		MyList := [1,2,3,4,5,6,7,8,9,10]
		Average(MyList) # == 5.5000
		StdDec(MyList) # == 3.0276
		Sum(MyList) # == 55

## List Comprehension

	Varaibles
		L as Integer[5]
	Body
		L := [1,2,3,4,5]
		[2*x for x in L where x < 4] # [2,4,6]
		[x*x for x in L] # [1,4,9,16,25]

## Generators

Generators can also be used and are useful in order to not require memory for the entire list.

	Varaibles
		L as Integer[5]
		G as Generator as Integer
	Body
		L := [1,2,3,4,5]
		G := [emit x*x for x in L]
		For x in G # G will only compute and store the current value of the generator
			x := x + 1

Methods can also be generators

	Methods
		Multiples(x as Integer) as Generator as Integer
			Variables
				cur as Integer
			Body
				Loop
					cur := 1
					Emit cur * x
					cur := 1 + cur
	Body
		For x in Multiples(4) #Now, this will loop forever...
			x := x + 1
		For x in Multiples(4) where x < 16 #This won't loop forever
			x := x + 1

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
## Loop
## For

``For`` loops iterate over iterable values (Sets, Enum, Generators, and Array).

	Variables
		L as Integer[5]
	Body
		L := [1,2,3,4,5]
		For x in L # Loops over 1 2 3 4 5
			x := x + 1 # Note, this won't modify L
		For x in L where x > 4 # Loops over 5
			x := x + 1 # Note, this won't modify L
		For x in L! # Loops over 1,2,3,4,5
			x := x + 1 # This _will_ modify L with value of x at the end of the block
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

The compiler should also ensure that the estimated execution time of each Every should fit into worst case gap between scheduled Every blocks.  The compiler should report what these worst-case gaps are, even if there is enough time.

## Rescue

Catches exceptions

	Rescue x as ConflictFault
		x := x + 1

# StdLib

## Units
* usec as Integer
 * msec as 1000 usec
 * sec as 1000 sec
 * min as 60 sec
* Radian as Fixed
 * RCircle as 6.2832 Radian
* miRadian as Integer
 * iRadian as 1000 miRadian
 * iRCircle as 6283 Radian
* mDegree as Integer
 * Degree as 1000 mDegree
 * DCircle as 360 Degree
* mGradian as Integer
 * Gradian as 1000 mGradian
 * GCircle as 400 Gradian

The ``Fixed`` type could almost be considered

* Decimal as Integer
 * Whole as 1000 Decimal

## Math
* Trig
 * Sin(rad as Radian) as Fixed
 * Sin(rad as iRadian) as Fixed
 * Sin(grad as Gradian) as Fixed
 * Sin(deg as Degree) as Fixed
 * Cos(rad as Radian) as Fixed
 * Cos(rad as iRadian) as Fixed
 * Cos(grad as Gradian) as Fixed
 * Cos(deg as Degree) as Fixed
 * Tan(rad as Radian) as Fixed
 * Tan(rad as iRadian) as Fixed
 * Tan(grad as Gradian) as Fixed
 * Tan(deg as Degree) as Fixed
 * aSin(rad as Radian) as Fixed
 * aSin(rad as iRadian) as Fixed
 * aSin(grad as Gradian) as Fixed
 * aSin(deg as Degree) as Fixed
 * aCos(rad as Radian) as Fixed
 * aCos(rad as iRadian) as Fixed
 * aCos(grad as Gradian) as Fixed
 * aCos(deg as Degree) as Fixed
 * aTan(rad as Radian) as Fixed
 * aTan(rad as iRadian) as Fixed
 * aTan(grad as Gradian) as Fixed
 * aTan(deg as Degree) as Fixed
 * Sinh(rad as Radian) as Fixed
 * Sinh(rad as iRadian) as Fixed
 * Sinh(grad as Gradian) as Fixed
 * Sinh(deg as Degree) as Fixed
 * Cosh(rad as Radian) as Fixed
 * Cosh(rad as iRadian) as Fixed
 * Cosh(grad as Gradian) as Fixed
 * Cosh(deg as Degree) as Fixed
 * Tanh(rad as Radian) as Fixed
 * Tanh(rad as iRadian) as Fixed
 * Tanh(grad as Gradian) as Fixed
 * Tanh(deg as Degree) as Fixed
 * aSinh(rad as Radian) as Fixed
 * aSinh(rad as iRadian) as Fixed
 * aSinh(grad as Gradian) as Fixed
 * aSinh(deg as Degree) as Fixed
 * aCosh(rad as Radian) as Fixed
 * aCosh(rad as iRadian) as Fixed
 * aCosh(grad as Gradian) as Fixed
 * aCosh(deg as Degree) as Fixed
 * aTanh(rad as Radian) as Fixed
 * aTanh(rad as iRadian) as Fixed
 * aTanh(grad as Gradian) as Fixed
 * aTanh(deg as Degree) as Fixed
* Misc
 * Loge(n as Fixed) as Fixed
 * Log2(n as Fixed) as Fixed
 * Log10(n as Fixed) as Fixed
 * Sqrt(n as Fixes as Fixed
 * Pow(n as Fixed, e as Fixed) as Fixed
 * Pow(n as Integer, e as Integer) as Integer
 * Pi() as Fixed
 * Pi2() as Fixed #Pi/2
 * Pi4() as Fixed #Pi/4
 * E() as Fixed
 * Phi() as Fixed
 * Gamma() as Fixed
 * Ceil(n as Fixed) as Integer
 * Floor(n as Fixed) as Integer
 * Round(n as Fixed, method as RoundingMethod) as Integer
 * Abs(n as Fixed) as Fixed
 * Abs(n as Integer) as Integer
 * GaussError(n as Fixed) as Fixed
 * GaussErrorCompl(n as Fixed) as Fixed
 * IsNaN(n as Fixed) as Boolean
 * IsNaN(n as Integer) as Boolean
 * RandSeed(seed as Integer) as None
 * Rand() as Integer
 * GaussRand(avg as Integer, stdev as Integer) as Integer

## Misc
* RoundingMethod
 * :RoundUp
 * :RoundDown
 * :RoundEven
 * :RoundOdd
 * :RoundToZero
 * :RoundAwayFromZero
* Serialize
* String
 * Methods
  * Concat(str as String)
  * Length()
  * Find(str as String)
  * Replace(search as String, replace as String)
* Faults
 * OverflowFault - Arithmetic overflow
 * UnderflowFault - Arithmetic underflow
 * TimeConstraintFault - An Every block executes late

# Statistics

* Sum
* Average
* SumOfSquares
* Variance
* StdDev
* SumOfCubes
* Skewness
* SumOfPow4
* Kurtosis

# Dates

* GregorianMonth
 * :January ....
 * Alias :Jan as :January ...
* GregorianDate
 * Alias Year as Integer
 * Alias Day as Integer
 * Extends (Year, Month, Day)
 * Rules to ensure good dates

# Operators

Math: +, -, *, /, %

Comparison: ==, <=, >=

Logic: &, |, ^, ->, <->
