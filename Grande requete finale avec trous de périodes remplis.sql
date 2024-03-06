--133

DECLARE @p_maxdate Date
SET @p_maxdate = '2024-09-25' -- (SELECT MAX(T_RefDate) FROM OFPR) --
DECLARE @p_mindate Date
SET @p_mindate = '2019-09-01' -- (SELECT MIN(F_RefDate) FROM OFPR) --
 
;
 
with GetDates As  
(  
	select 
		1 as counter, 
		DATEADD(day,0,@p_mindate) as Date   
	UNION ALL  
	select 
		counter + 1, 
		DATEADD(day,counter,@p_mindate)  
	from 
		GetDates  
	where 
		DATEADD(day, counter, @p_mindate) < @p_maxdate  
	),
 
	AccPeriods As (
	SELECT Code, F_RefDate, T_RefDate FROM OFPR WITH (NOLOCK)
),

DatesFormattedMatrix AS (

SELECT AccPeriods.*, GD1.Date AS PostingDate 
FROM AccPeriods
LEFT JOIN GetDates GD1 ON GD1.Date BETWEEN AccPeriods.F_RefDate AND AccPeriods.T_RefDate
--option (maxrecursion 0)
--select Date from GetDates option (maxrecursion 0)

),
 
AccountsBalanceData AS (

	SELECT 
		Account,
		AcctName,
		CompteCollectif,
		--RefDate,
		Code,
		ISNULL(OpeningBalance,0) OpeningBalance,
		ISNULL(ClosingBalance,0) ClosingBalance

	FROM(

		SELECT 
			Account, 
			AcctName,
			CompteCollectif, 
			RefDate,
			Code,
			SUM(Balance) OVER(PARTITION BY Account, CompteCollectif ORDER BY RefDate ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS 'OpeningBalance',
			SUM(Balance) OVER(PARTITION BY Account, CompteCollectif ORDER BY RefDate) AS 'ClosingBalance'
		FROM (
			SELECT 
				Account, 
				OACT.AcctName,
				OACT.Segment_0 + '-' + OACT.Segment_1 + '-' + OACT.Segment_2 AS 'CompteCollectif',
				e.F_RefDate as RefDate,
				SUM(JDT1.Debit) - SUM(JDT1.Credit) AS 'Balance',
				Code
			FROM 
				OACT WITH (NOLOCK)
			INNER JOIN 
				JDT1 WITH (NOLOCK) ON OACT.AcctCode = JDT1.Account
			LEFT JOIN 
				DatesFormattedMatrix e ON JDT1.RefDate = e.PostingDate
			GROUP BY 
				Account, 
				OACT.AcctName,
				OACT.Segment_0 + '-' + OACT.Segment_1 + '-' + OACT.Segment_2, 
				e.F_RefDate,
				Code
		) AS TAB
	) AS TAB2

),

DistinctAccounts AS (
SELECT distinct AcctCode, AcctName, Segment_0, Segment_1, Segment_2
FROM OACT WITH (NOLOCK)
)
, 
DistinctPeriodsAccounts AS (
SELECT distinct A.Code, A.F_RefDate , B.AcctCode, B.AcctName, B.Segment_0, B.Segment_1, B.Segment_2
FROM DatesFormattedMatrix A
LEFT JOIN DistinctAccounts B ON 1=1 
WHERE F_RefDate >= @p_mindate
),

MergedBalanceAndPeriods AS (
SELECT A.Code, A.AcctCode, A.AcctName, A.Segment_0, A.Segment_1, A.Segment_2, B.OpeningBalance, B.ClosingBalance

FROM  DistinctPeriodsAccounts A 

LEFT JOIN AccountsBalanceData B ON A.AcctCode = B.Account AND A.Code = B.Code


) 

, RankedBalances AS (
  SELECT
    Code,
	AcctCode,
    AcctName,
    Segment_0,
    Segment_1,
    Segment_2,
    OpeningBalance,
    ClosingBalance,
    -- Rank rows within each account partition, ordered by Code
    ROW_NUMBER() OVER (PARTITION BY AcctName, Segment_0, Segment_1, Segment_2 ORDER BY Code) AS rn,
    -- Count non-null ClosingBalance values within each account partition, ordered by Code
    COUNT(ClosingBalance) OVER (PARTITION BY AcctName, Segment_0, Segment_1, Segment_2 ORDER BY Code ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS nonNullBalances
  FROM
    MergedBalanceAndPeriods
),
FilledBalances AS (
  SELECT
    Code,
	AcctCode,
    AcctName,
    Segment_0,
    Segment_1,
    Segment_2,
    -- Use last non-null ClosingBalance as OpeningBalance if OpeningBalance is null
    CASE WHEN OpeningBalance IS NULL AND nonNullBalances > 0 THEN FIRST_VALUE(ClosingBalance) OVER (PARTITION BY AcctCode, nonNullBalances ORDER BY rn) ELSE OpeningBalance END AS OpeningBalance,
    -- Use last non-null ClosingBalance as ClosingBalance if ClosingBalance is null
    CASE WHEN ClosingBalance IS NULL AND nonNullBalances > 0 THEN FIRST_VALUE(ClosingBalance) OVER (PARTITION BY AcctCode, nonNullBalances ORDER BY rn) ELSE ClosingBalance END AS ClosingBalance
  FROM RankedBalances
)
SELECT
  Code,
  AcctCode,
  AcctName,
  Segment_0,
  Segment_1,
  Segment_2,
  OpeningBalance,
  ClosingBalance,
  ClosingBalance - OpeningBalance AS 'variation débit/crédit'
FROM FilledBalances

WHERE OpeningBalance IS NOT NULL 

--AND Segment_0 = '101800' and Segment_1 = '00'

ORDER BY AcctCode, Code

option (maxrecursion 0)








