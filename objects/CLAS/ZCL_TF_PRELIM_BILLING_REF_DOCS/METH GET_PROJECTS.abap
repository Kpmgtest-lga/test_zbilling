METHOD get_projects
  BY DATABASE FUNCTION FOR HDB
  LANGUAGE SQLSCRIPT
  OPTIONS READ-ONLY
  USING ZI_PRELIM_BILLING_ITEM_RAW.

  -- Step 1: Pre-deduplicate WBS Elements per billing document
  lt_distinct_wbs =
    SELECT DISTINCT
      prelimbillingdocument,
      ProjectExternalID
    FROM ZI_PRELIM_BILLING_ITEM_RAW
    WHERE ProjectExternalID IS NOT NULL
      AND ProjectExternalID <> '';


  -- Step 2: Count unique items and build concatenated string WBS per billing document
  lt_counted_wbs =
    SELECT
      prelimbillingdocument,
      COUNT(*)                                     AS item_count,
      STRING_AGG( ProjectExternalID, ', '
                  ORDER BY ProjectExternalID )     AS concatenated
    FROM :lt_distinct_wbs
    GROUP BY prelimbillingdocument;


-- Step 3: Apply threshold logic show list if <= 3, show "N items" if > 3
    RETURN
    SELECT
      session_context( 'CDS_CLIENT' )              AS client,
      prelimbillingdocument          AS PrelimBillingDocument,
      CAST( CASE
              WHEN item_count > 2
              THEN TO_NVARCHAR( item_count ) || ' items'
              ELSE concatenated
            END
            AS NVARCHAR( 1333 ) )                  AS concatenatedprojects
    FROM :lt_counted_wbs;


ENDMETHOD.