# Exercise 3 - DAX Challenges (do these in your existing PropertyAnalysis .pbix)

Create each measure in FactPropertyValue. Test by dropping it into a card or table
visual next to your slicers - the interesting part is watching how each one reacts
(or refuses to react) to slicer clicks.

Answers are at the bottom - scroll carefully, try first!

---

**D1 (warm-up).** `Max Property Value` - the highest median value visible under the
current filters.

**D2.** `NSW Average (fixed)` - the average value that IGNORES all slicers and always
shows the whole-state average. Drop it next to your normal average and click slicers:
one moves, one doesn't.
*Concept: CALCULATE + ALL*

**D3.** `% vs NSW Average` - the selected area's average as a percentage of D2.
Format as percentage. Sydney suburbs should mostly be above 100%.

**D4.** `Suburb Rank` - rank of each suburb by average value, 1 = most expensive,
rank recalculates as you filter city.
*Concept: RANKX + ALLSELECTED*

**D5.** `Suburbs Counted` - how many distinct suburbs contribute to the current filter.
Useful sanity-check card next to your map.

**D6.** `Value Range` - a text measure showing "min - max", like "$450,000 - $3,210,000".
*Concept: FORMAT and string concatenation with &*

**D7.** `Avg of Top 10 Suburbs` - the average value across only the 10 most expensive
suburbs in the current selection.
*Concept: TOPN inside AVERAGEX*

**D8 (stretch).** `City Share of Selected` - with several cities selected in a slicer,
each city row in a table shows its % of the total across the SELECTED cities only
(not all of NSW). This one teaches the difference between ALL and ALLSELECTED - the
distinction most people learn the hard way.

---
---

## Answers

```dax
-- D1
Max Property Value = MAX ( FactPropertyValue[PropertyMedianValue] )

-- D2
NSW Average (fixed) =
CALCULATE (
    AVERAGE ( FactPropertyValue[PropertyMedianValue] ),
    ALL ( DimLocation )
)

-- D3
% vs NSW Average =
DIVIDE ( [Avg Property Median Value], [NSW Average (fixed)] )

-- D4
Suburb Rank =
RANKX (
    ALLSELECTED ( DimLocation[Suburb] ),
    [Avg Property Median Value],
    ,
    DESC
)

-- D5
Suburbs Counted = DISTINCTCOUNT ( DimLocation[Suburb] )

-- D6
Value Range =
FORMAT ( MIN ( FactPropertyValue[PropertyMedianValue] ), "$#,0" )
    & " - "
    & FORMAT ( MAX ( FactPropertyValue[PropertyMedianValue] ), "$#,0" )

-- D7
Avg of Top 10 Suburbs =
AVERAGEX (
    TOPN (
        10,
        VALUES ( DimLocation[Suburb] ),
        [Avg Property Median Value], DESC
    ),
    [Avg Property Median Value]
)

-- D8
City Share of Selected =
DIVIDE (
    [Avg Property Median Value],
    CALCULATE (
        [Avg Property Median Value],
        ALLSELECTED ( DimLocation[City] )
    )
)
```

**The lesson hiding in D2 vs D8:** ALL removes every filter (the whole state, always);
ALLSELECTED removes only the filters coming from the visual itself but keeps your
slicer choices. Understanding this difference is 80% of "advanced DAX".
