# Future Improvements, Bug Fixes and Contibution Ideas

1. Attempt to address MemoryError problems due to complex query processing during export. Possible solutions include creating a temporary table before export and pausing execution till complete, or possibly increasing the cache wait time.
2. Create an import methodology that works for non-windows systems. Something along the lines of python code that will extract the DIMA tables to a tab, comma, or pipe delimited file.
3. Do a thorough sample/test of output values on all different scales to ensure total accuracy of calculations.  This has been done to a certain extent, but a full audit would be helpful.
4. Implement more robust error catching.  Most failures at this point will just raise an exception, which is useful in debugging but not a good method for non-developers to understand why things failed.
5. Implement more options for output. Currently MS Excel is only option.
6. Create a simpler option for altering QC queries for different projects than altering full view definitions.  Possible options include some sort of variable lookup table or perhaps some sort of variable storage in a json file.
