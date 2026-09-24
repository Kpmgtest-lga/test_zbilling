METHOD get_ref_docs
  BY DATABASE FUNCTION FOR HDB
  LANGUAGE SQLSCRIPT
  OPTIONS READ-ONLY
  USING ZI_PRELIM_BILLING_ITEM_RAW.



  -- Step 1: Pre-deduplicate reference documents per billing document
  lt_distinct =
    SELECT DISTINCT
      prelimbillingdocument,
      referencedocument
    FROM ZI_PRELIM_BILLING_ITEM_RAW
    WHERE referencedocument IS NOT NULL
      AND referencedocument <> '';

  -- Step 2: Count unique items and build concatenated string per billing document
  lt_counted =
    SELECT
      prelimbillingdocument,
      COUNT(*)                                     AS item_count,
      STRING_AGG( referencedocument, ', '
                  ORDER BY referencedocument )     AS concatenated
    FROM :lt_distinct
    GROUP BY prelimbillingdocument;

-- Step 3: Apply threshold logic show list if <= 3, show "N items" if > 3
    RETURN
    SELECT
      session_context( 'CDS_CLIENT' )              AS client,
      prelimbillingdocument          AS PrelimBillingDocument,
      CAST( CASE
              WHEN item_count > 3
              THEN TO_NVARCHAR( item_count ) || ' items'
              ELSE concatenated
            END
            AS NVARCHAR( 1333 ) )                  AS concatenatedreferencedocs
    FROM :lt_counted;

ENDMETHOD.