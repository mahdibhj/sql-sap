

DECLARE @DateFrom Date ; 

DECLARE @DateTo Date ;

SET @DateFrom = '2023-10-01' ;

SET @DateTo = '2023-10-31' ;


WITH BaseQuery AS (

SELECT  --OJDT.BaseRef, OJDT.TransType,

NNM1.SeriesName, OJDT.TransType,
OJDT.CreateDate 'Date enregistrement' , 
JDT1.DueDate 'Date échéance', 
JDT1.TaxDate 'Date du document',
JDT1.RefDate 'Date de posting',

--Trouver la date comptable qui est le Posting Date

JDT1.Ref1 'Numéro de document', 
JDT1.TransId 'No Transaction',
OACT.Segment_0 + '-' + OACT.Segment_1 + '-' + OACT.Segment_2 'Compte collectif' ,
JDT1.LineMemo 'Remarques', OACT.AcctName 'Nom compte de contrepartie', 
CASE WHEN JDT1.Debit > 0 THEN JDT1.Debit ELSE -1*JDT1.Credit END AS 'Débit/Crédit (DI)',
CASE WHEN JDT1.FCDebit > 0 THEN JDT1.FCDebit ELSE -1*JDT1.FCCredit END AS 'Débit/Crédit (FC)',
JDT1.Project , OPRJ.PrjName, 
JDT1.Ref1 'Ref. 1 (ligne)',
JDT1.Ref2 'Réf. 2 (Ligne)',
JDT1.Ref3Line 'Réf. 3 (Ligne)',
OJDT.Ref1 'Ref. 1 (header)',
OJDT.Ref2 'Ref. 2 (header)',
OJDT.Ref3 'Ref. 3 (header)', 
OUSR.U_NAME
FROM OACT WITH (NOLOCK) 
LEFT JOIN JDT1 WITH (NOLOCK) ON OACT.AcctCode = JDT1.Account
LEFT JOIN OJDT WITH (NOLOCK) ON OJDT.TransId = JDT1.TransId
LEFT JOIN OPRJ WITH (NOLOCK) ON JDT1.Project = OPRJ.PrjCode
LEFT JOIN NNM1 WITH (NOLOCK) ON OJDT.Series = NNM1.Series
LEFT JOIN OUSR WITH (NOLOCK) ON OJDT.UserSign = OUSR.USERID
WHERE 
JDT1.RefDate BETWEEN @DateFrom AND @DateTo
--AND OJDT.TransType = '67'  

),
--ORDER BY OACT.FormatCode ASC, JDT1.RefDate ASC ;

AdditionalInfosBase AS (

SELECT DocNum, CardCode, CardName, UserSign, ObjType FROM ORCT WITH(NOLOCK) --WHERE DocNum = '22690'
UNION ALL
SELECT DocNum, CardCode, CardName, UserSign, ObjType FROM OVPM WITH(NOLOCK) --WHERE DocNum = '38001'
UNION ALL
SELECT DocNum, CardCode, CardName, UserSign, ObjType FROM OPCH WITH(NOLOCK) --WHERE DocNum = '96842'
UNION ALL
SELECT DocNum, CardCode, CardName, UserSign, ObjType FROM ODLN WITH(NOLOCK) --WHERE DocNum = '5298409'
UNION ALL
SELECT DocNum, CardCode, CardName, UserSign, ObjType FROM OIGN WITH(NOLOCK) --WHERE DocNum = '330882'
UNION ALL
SELECT DocNum, CardCode, CardName, UserSign, ObjType FROM OINV WITH(NOLOCK) --WHERE DocNum = '4027641'
UNION ALL
SELECT DocNum, CardCode, CardName, UserSign, ObjType FROM ORIN WITH(NOLOCK) --WHERE DocNum = '92388'
UNION ALL
SELECT DocNum, CardCode, CardName, UserSign, ObjType FROM ORPC WITH(NOLOCK) --WHERE DocNum = '974'
UNION ALL
SELECT DocNum, CardCode, CardName, UserSign, ObjType FROM OPDN WITH(NOLOCK) --WHERE DocNum = '66325'
UNION ALL
SELECT DocNum, CardCode, CardName, UserSign, ObjType FROM OIGE WITH(NOLOCK) --WHERE DocNum = '76640'
UNION ALL
SELECT DeposNum as DocNum, NULL as CardCode, NULL as CardName, UserSign, ObjType FROM ODPS WITH(NOLOCK) --WHERE DeposNum = '1844'
UNION ALL
SELECT DocNum, CardCode, CardName, UserSign, ObjType FROM OWTR WITH(NOLOCK) --WHERE DocNum = '2143'
--UNION ALL
--SELECT *, UserSign, ObjType FROM OJDT WITH(NOLOCK) --WHERE DocNum = '2143'


),

FullAdditionalInfos AS (

SELECT AdditionalInfosBase.*, OCRD.FatherCard, OUSR.U_NAME, FatherOCRD.CardName FatherCardName
FROM AdditionalInfosBase
LEFT JOIN OCRD WITH(NOLOCK) ON AdditionalInfosBase.CardCode = OCRD.CardCode 
LEFT JOIN OUSR WITH(NOLOCK) ON AdditionalInfosBase.UserSign = OUSR.USERID 
LEFT JOIN OCRD FatherOCRD WITH(NOLOCK) ON OCRD.FatherCard = FatherOCRD.CardCode
)


SELECT 
	BaseQuery.SeriesName,
	BaseQuery.TransType ,
	BaseQuery.[Date enregistrement] ,
	BaseQuery.[Date échéance] ,
	BaseQuery.[Date du document] ,
	BaseQuery.[Date de posting] ,
	BaseQuery.[Numéro de document] ,
	BaseQuery.[No Transaction] ,
	BaseQuery.[Compte collectif] ,
	BaseQuery.Remarques ,
	BaseQuery.[Nom compte de contrepartie] ,
	BaseQuery.[Débit/Crédit (DI)] ,
	BaseQuery.[Débit/Crédit (FC)] ,
	BaseQuery.Project ,
	BaseQuery.PrjName ,
	BaseQuery.[Ref. 1 (ligne)] ,
	BaseQuery.[Réf. 2 (Ligne)] ,
	BaseQuery.[Réf. 3 (Ligne)] ,
	BaseQuery.[Ref. 1 (header)] ,
	BaseQuery.[Ref. 2 (header)] ,
	BaseQuery.[Ref. 3 (header)] ,
	FullAdditionalInfos.CardCode,
	FullAdditionalInfos.CardName,
	FullAdditionalInfos.FatherCard, 
	FullAdditionalInfos.FatherCardName, 
	CASE WHEN BaseQuery.TransType = '30' THEN BaseQuery.U_NAME ELSE FullAdditionalInfos.U_NAME END AS RESOURCE_NAME
FROM BaseQuery
LEFT JOIN FullAdditionalInfos ON CAST(BaseQuery.TransType AS nvarchar) = CAST(FullAdditionalInfos.ObjType AS nvarchar) AND CAST(BaseQuery.[Numéro de document] AS nvarchar) = CAST(FullAdditionalInfos.DocNum AS nvarchar)


--ORDER BY BaseQuery.[No Transaction] DESC




