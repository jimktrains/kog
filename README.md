# Kog

This language is designed to aid in the programming of Real-Time systems, specifically memory-constrained microcontrollers.

# A Basic Program

* Sections
    * Types
    * Variables
    * Properties
    * Rules
    * Program
        * Every
         * Rescue
        * Function
         * Rescue
        * Rescue

## Types

` <Type Name> as <Type Definition>`

This is where types are aliased or composed. Type Definition is a:
* Type Name
* Type Name with an optional array size definition
* Composite
** Like a struct

## Variables

`<Varaible Name> as <Type Name>`

This is where all variables, with the exception of Function and Rescue parameters

## Properties

`Property <Property Name>(<Parm Name> as <Type Name>, ... ): <logic expression>`

These are functions that return bool and whose body is a single logical expression.  The expression may only call another property

## Rules

`Rule <Fault Type>(<Varaible Name>, ...): <logical expression>`

Rules are checked every time a variable defined in the rule's definition is set.  Like a property, it can only consist of a single logical expression who may only call properties.  If the Rule returns falls, the rule's type is thrown as a fault.

## Program

Code to be executed

## Function

`Function <Function Name>(<Parm Name> as <Type Name>, ...) { <code> }`

General purpose function

## Rescue

`Rescue <Varaible Name> as <Fault Type> { code }`

Rescue sections catch faults by type and handle them appropriately

## Every

`Every <time> <time unit> { <code> }`


Executes the code every so many units of time.  Every blocks may not be multiples of each other; those should be nested inside the higher precision block.

If an Every section does not finish before it is triggered again, a TimeConstraintViolated fault is raised.

# TODO

* Get Parser Working
* Create AST
* Create Interpreter
* Create AVR ASM
