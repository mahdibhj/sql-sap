
------------------------------------------------------- Factures recevables de NOI - Requête qui va nourrir le crystal report -------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

WITH OINV_CTE AS (
SELECT DocEntry, DocTotal, CardCode, CardName, FatherCard,CntctCode,GroupNum,PayToCode,Address,Address2,TrnspCode,DocNum,DocDate,NumAtCard, VatSum, U_FCSDK_ROUTE  FROM OINV  WHERE DocEntry = {?DocKey@}
),
INV1_CTE AS(
SELECT DocEntry,BaseEntry,ItemCode,Quantity INV1_Qty,Price,WhsCode,Dscription ItemDescription, LineTotal, LineNum, 'INV1' as 'Table'  FROM INV1 WHERE ItemCode != 'R-O'


UNION ALL 

SELECT DocEntry,'' BaseEntry,'' ItemCode, null INV1_Qty,null Price,'' WhsCode,LineText as ItemDescription,null LineTotal, null LineNum, 'INV10' as 'Table'  FROM INV10 --WHERE DocEntry = '17803'

),
OITL_CTE AS(
SELECT DocEntry,LogEntry,ItemCode,ItemName,DocQty FROM OITL
),
ITL1_CTE AS (
SELECt LogEntry, ItemCode, -1*Quantity ITL1_Qty, MdAbsEntry FROM ITL1 WHERE  Quantity < 0
),
OITL_ITL1_CTE AS (
SELECT OITL_CTE.LogEntry lgEntry,OITL_CTE.DocEntry dcEntry,ITL1_CTE.* FROM OITL_CTE
INNER JOIN ITL1_CTE ON OITL_CTE.LogEntry = ITL1_CTE.LogEntry
),
OBTQ_CTE AS(
SELECT WhsCode, MdAbsEntry FROM OBTQ 
),
OBTN_CTE AS(
SELECT AbsEntry,DistNumber,LotNumber,ExpDate FROM OBTN
),
OCRD_CTE AS(
SELECT CardCode, LangCode,Phone1,Phone2, U_CHAINES FROM OCRD
),
OCPR_CTE AS(
SELECT CntctCode,Name FROM OCPR
),
INV1_SUM_CTE AS(
SELECT DocEntry, SUM(LineTotal) SUM_LineTotal FROM INV1 --WHERE DocEntry = '17803'
GROUP BY DocEntry
),
INV1_QTY_CTE AS(
SELECT DocEntry, LineNum, SUM(Quantity) SUM_Quantity_INV1, SUM(LineTotal) SUM_LineTotal_Item FROM INV1 --WHERE DocEntry = '17803'
GROUP BY DocEntry, LineNum
),
ODLN_DLN1_CTE AS (
SELECT ODLN.DocEntry, DLN1.LineNum, ODLN.DocNum ODLN_DocNum FROM ODLN
LEFT JOIN DLN1 ON ODLN.DocEntry = DLN1.DocEntry
),
OCTG_CTE AS (
SELECT GroupNum, PymntGroup FROM OCTG
),
OSHP_CTE AS (
SELECT TrnspCode,TrnspName FROM OSHP
),
OITM_CTE AS (
SELECT ItemCode,FrgnName,ItemName, U_FCSDK_EMBALLAGE, U_DOUZ, U_UNITES, codebars,
CASE WHEN ItemCode = '' THEN 2 WHEN (ItemCode = 'PAL' OR ItemCode = 'PALPROD') THEN 3 WHEN ItemCode LIKE 'EMB%' THEN 4 ELSE 0 END AS ProductOrder
FROM OITM
),
EMBALLAGE_CTE AS (
SELECT Code, Name as Emballage_Name
FROM [@FCSDK_EMBALLAGE]
),
ROUTE_CTE AS (
SELECT Code, Name as Route 
FROM [@FCSDK_ROUTEHDR]
),
OITM_BASE_CTE AS (
SELECT Base_ItemCode, ItemCode, Base_U_DOUZ FROM V_NUTRI_OITM_BASE
)

SELECT * FROM OCRD_CTE 
INNER JOIN OINV_CTE ON OCRD_CTE.CardCode = OINV_CTE.CardCode
LEFT JOIN INV1_CTE ON OINV_CTE.DocEntry = INV1_CTE.DocEntry
LEFT JOIN OITL_ITL1_CTE ON OITL_ITL1_CTE.DcEntry = INV1_CTE.BaseEntry AND OITL_ITL1_CTE.ItemCode = INV1_CTE.ItemCode
LEFT JOIN OBTQ_CTE ON OITL_ITL1_CTE.MdAbsEntry = OBTQ_CTE.MdAbsEntry AND INV1_CTE.WhsCode = OBTQ_CTE.WhsCode
LEFT JOIN OBTN_CTE ON OBTQ_CTE.MdAbsEntry = OBTN_CTE.AbsEntry
LEFT JOIN OCPR_CTE ON OCPR_CTE.CntctCode = OINV_CTE.CntctCode
LEFT JOIN INV1_SUM_CTE ON INV1_SUM_CTE.DocEntry = OINV_CTE.DocEntry
LEFT JOIN ODLN_DLN1_CTE ON ODLN_DLN1_CTE.DocEntry = INV1_CTE.BaseEntry AND ODLN_DLN1_CTE.LineNum = INV1_CTE.LineNum
LEFT JOIN OCTG_CTE ON OCTG_CTE.GroupNum = OINV_CTE.GroupNum
LEFT JOIN OSHP_CTE ON OSHP_CTE.TrnspCode = OINV_CTE.TrnspCode
LEFT JOIN OITM_CTE ON INV1_CTE.ItemCode = OITM_CTE.ItemCode
LEFT JOIN INV1_QTY_CTE ON INV1_QTY_CTE.DocEntry = INV1_CTE.DocEntry   AND INV1_QTY_CTE.LineNum = INV1_CTE.LineNum
LEFT JOIN EMBALLAGE_CTE ON EMBALLAGE_CTE.Code = OITM_CTE.U_FCSDK_EMBALLAGE
LEFT JOIN ROUTE_CTE  ON ROUTE_CTE.Code = OINV_CTE.U_FCSDK_ROUTE
LEFT JOIN OITM_BASE_CTE ON OITM_BASE_CTE.ItemCode = OITM_CTE.ItemCode

WHERE INV1_CTE.ItemCode NOT LIKE '%R-O%'

