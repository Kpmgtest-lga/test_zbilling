METHOD get_projects_bd
  BY DATABASE FUNCTION FOR HDB
  LANGUAGE SQLSCRIPT
  OPTIONS READ-ONLY
  USING ZI_BILLNG_DOC_ITEM_BASIC_RAW.

  -- Step 1: Pre-deduplicate WBS Elements per billing document
  lt_distinct_wbs_bd =
    SELECT DISTINCT
      billingdocument,
      ProjectExternalID
    FROM ZI_BILLNG_DOC_ITEM_BASIC_RAW
    WHERE ProjectExternalID IS NOT NULL
      AND ProjectExternalID <> '';


  -- Step 2: Count unique items and build concatenated string WBS per billing document
  lt_counted_wbs_bd =
    SELECT
      billingdocument,
      COUNT(*)                                     AS item_count,
      STRING_AGG( ProjectExternalID, ', '
                  ORDER BY ProjectExternalID )     AS concatenated
    FROM :lt_distinct_wbs_bd
    GROUP BY billingdocument;


-- Step 3: Apply threshold logic show list if <= 3, show "N items" if > 3
    RETURN
    SELECT
      session_context( 'CDS_CLIENT' )              AS client,
      billingdocument          AS BillingDocument,
      CAST( CASE
              WHEN item_count > 2
              THEN TO_NVARCHAR( item_count ) || ' items'
              ELSE concatenated
            END
            AS NVARCHAR( 1333 ) )                  AS concatenatedprojectsbd
    FROM :lt_counted_wbs_bd;


ENDMETHOD.