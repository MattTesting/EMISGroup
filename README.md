>>Files

> DataProfiling.sql
This file hosts the code used for searching for named columns and a data profiling script.  (Credits for sources included).
> Part1_build.sql
This file was the testing code to build the output for the submission and includes investigation code and testing.  
> Part1.sql
This is the query submitted for Part 1.  It includes queries demonstrating the distribution of patients by postcode and/or gender.
> Part2_build.sql
This is the testing code for Part 2 and looks at each of the requirements and tests my understanding of relationships between tables.
> Part2.sql
This is the final version but with some options disabled.  My code could not identify the medication/drug requirements in a way that
returned any results so this file opened up the data to the top 5 postcode (outbound) and removed the constraint on medication/drugs.
> Part2_final.sql
This is the query submitted for Part2.  It returns zero records due to the medication constraint as I have implemented it.

>>Environment
The data was loaded into a desktop build of SQL Server 2022 Express and uses SSMS v19

>>Best Practice
>Variables.  There is a date calculation in the code for 'the last 30 years'.  Depending on how often this is required and the range of values, it may be worth pushing this calculation into a variable and embedding it at the start of the code.
>Temp tables over common table expressions.  I've used temp tables because I can control and validate at different times through the development process.  With CTEs I'd have to query the source data each time which may not be appropriate on some production systems
>If this is a regular query format, there may be scope to write this as a stored procedure but that will probably require some form of metadata tables to define the constriants.  It may be more appropriate to use tools such Power BI if there's no structure to the constriants.

>>Potential Improvements
As part of familiarising myself with the datasets I've built the output using multiple blocks of code; asthma, medication, weight and saved them to temp tables.  This enabled me to validate volumes at each stage and highlighted a couple of code corrections I needed.
Once I'm more familiar with the data structures I would look to reduce the number of queries by blending some items e.g. 'most recent' indicators for weight, smoking, drug use into a single query.  This may also be a candidate for DWH refreshes to recalculate the logic.
Because I used temp tables rather than CTE's I was able to add indexes into the code.  They are a bit overkill at this point but once scaled up to a large healthcare organisation there will be millions of records so it made sense to implement them at this stage.

>>Testing
>Testing had different stagees; data profiling and relationship mapping.
>I'm not sure I have the relationships for medication correct as it returned zero in my output.  The parent child logic in clinical codes might need additional review.
>Using temp tables allowed me to test volumes for each logical part of the specification.  
>Ideally, I'd be able to see the software application and valdiate my figures using that e.g. This patient was prescribed this drug on date X, is that correct?
