# Exercise 1 - Data Consolidation Drill (prep for "AU Property Data Collection and Consolidation")

## The scenario
You received the same NSW property data from three different "providers", and each one
formatted it their own way (this is exactly what happens in real projects):

| File | Format | The traps hiding inside |
|---|---|---|
| Source1_Sydney_Metro.csv | CSV, UPPERCASE headers | Two different state labels; some suburbs have trailing spaces |
| Source2_Regional_NSW.xlsx | Excel, lowercase headers | Value is in THOUSANDS ($K); date is combined "2017-06"; city is Title Case |
| Source3_Agency_Extract.txt | Pipe-delimited (\|) text | Value is text like "$1,044,350"; date is "6/2017"; UPPERCASE suburbs; 25 duplicate rows; 3 junk rows (postcode 'abc', month 13, value 'N/A') |

## Your mission
Build ONE SSIS package (or do it in pure SQL first if you prefer) that loads all three
files into a single clean staging table with these columns:

    State, City, Suburb, Postcode (INT), PropertyMedianValue (MONEY), UpdatedYear (INT), UpdatedMonth (INT), SourceFile

## Success checklist
- [ ] All three files land in one table with a SourceFile column saying where each row came from
- [ ] Values from Source2 multiplied back to full dollars
- [ ] The "$1,044,350" text values converted to numbers (hint: REPLACE twice, then TRY_CAST)
- [ ] Both date formats split into year + month numbers
- [ ] Suburbs trimmed and in consistent casing (pick one: UPPER or Title)
- [ ] The 25 duplicates removed (hint: ROW_NUMBER() OVER (PARTITION BY ...))
- [ ] The 3 junk rows rejected, not loaded (month must be 1-12, postcode must be numeric, value > 0)
- [ ] Row count check: Source1 = 4,589 | Source2 = 85 | Source3 = 208 raw, but fewer after dedup + junk removal

## Hints if stuck (try without them first!)
1. Flat File Connection Manager for Source3: set the column delimiter to Vertical Bar (|).
2. Data Conversion can't do math - use a Derived Column for the x1000.
3. For "$1,044,350": Derived Column expression
   (DT_CY)REPLACE(REPLACE(VALUE_AUD,"$",""),",","")
4. For "6/2017": TOKEN(PERIOD,"/",1) is the month, TOKEN(PERIOD,"/",2) is the year.
5. Dedup easiest AFTER loading, in SQL:
   DELETE T FROM (SELECT *, ROW_NUMBER() OVER (PARTITION BY Suburb, Postcode, UpdatedYear, UpdatedMonth, PropertyMedianValue ORDER BY (SELECT 1)) rn FROM stage) T WHERE rn > 1;

When you finish, show me your package screenshot + row counts and I'll review it like a mentor would.
