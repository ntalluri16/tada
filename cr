DECLARE
  given_date DATE := TO_DATE('2025-07-18', 'YYYY-MM-DD');  -- Replace with actual date
BEGIN
  MERGE INTO z_account t
  USING (
    -- Begin inline view (derived table)
    WITH filtered_stage AS (
      SELECT 
        LPAD(s.account_number, 10, '0') AS account_number,
        s.short_description,
        SUBSTR(s.long_description, 1, 20) AS long_description,
        s.random_field,
        s.start_date,
        s.row_id
      FROM z_account_stage s
      WHERE s.active = 'Y'
        AND given_date BETWEEN s.start_date AND s.end_date
    ),
    ranked_stage AS (
      SELECT *
      FROM (
        SELECT fs.*,
               ROW_NUMBER() OVER (
                 PARTITION BY fs.account_number, fs.start_date
                 ORDER BY fs.row_id
               ) AS rn
        FROM filtered_stage fs
      )
      WHERE rn = 1
    )
    SELECT account_number, short_description, long_description, random_field
    FROM ranked_stage
    -- End inline view
  ) s
  ON (t.account_number = s.account_number)
  WHEN MATCHED THEN
    UPDATE SET
      t.short_description = s.short_description,
      t.long_description  = s.long_description,
      t.random_field      = s.random_field
    WHERE t.short_description != s.short_description
       OR t.long_description != s.long_description
       OR t.random_field != s.random_field
  WHEN NOT MATCHED THEN
    INSERT (account_number, short_description, long_description, random_field)
    VALUES (s.account_number, s.short_description, s.long_description, s.random_field);
END;
/
