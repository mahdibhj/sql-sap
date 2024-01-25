USE [**SERVER-NAME**]
GO
 
/****** Object:  View [dbo].[products_out_tracking]    Script Date: 2023-09-12 16:21:54 ******/
SET ANSI_NULLS ON
GO
 
SET QUOTED_IDENTIFIER ON
GO
 
 
CREATE VIEW [dbo].[sales_tracking] AS
 
 
SELECT DISTINCT *
 
FROM(
 
  SELECT 
    --ORDR.DocEntry 'Order DB reference',
    --'1' 'Query Bloc',
    ORDR.DocNum 'Order number',  
    ODLN.DocNum 'Delivery number',
    OINV.DocNum 'Invoice number',
    OBTN.DistNumber 'Lot number',
    OINV.CardCode 'Costumer code',
    OINV.CardName 'Customer name',
    RDR1.ItemCode 'Product code',
    RDR1.Dscription 'Product description',
    OITL.DocDate 'Transaction log date',
    RDR1.ShipDate,
    RDR1.Quantity 'Ordered qty',
    ISNULL(DLN1.Quantity,0) 'Delivered qty' ,
    INV1.Quantity 'Invoiced quantity',
    ITL1.Quantity 'Lot quantity',
    INV1.Price 'Invoiced unit price',
    'Closed' 'Order status'
    --ITL1.LogEntry 'log details reference'
    --,OITL.*
  from ORDR 
  INNER JOIN RDR1  on ORDR.DocEntry=RDR1.DocEntry AND RDR1.ItemCode != 'PAL'
  LEFT JOIN DLN1 on DLN1.BaseEntry=RDR1.DocEntry AND DLN1.ItemCode = RDR1.ItemCode
  LEFT JOIN ODLN ON ODLN.DocEntry=DLN1.DocEntry 
  INNER JOIN INV1 ON INV1.BaseEntry = RDR1.TrgetEntry AND INV1.ItemCode = RDR1.ItemCode AND RDR1.WhsCode = INV1.WhsCode
  LEFT JOIN OINV ON OINV.DocEntry = INV1.DocEntry
  LEFT JOIN OITL ON OITL.DocEntry = INV1.BaseEntry  AND OITL.ItemCode = INV1.ItemCode AND OITL.StockEff = 1 AND OITL.DefinedQty != 0 AND OITL.ApplyType = '15' --OITL.DocEntry = INV1.BaseEntry 
  LEFT JOIN ITL1 ON OITL.LogEntry = ITL1.LogEntry 
  LEFT JOIN OBTN ON OBTN.Itemcode = ITL1.ItemCode AND OBTN.SysNumber = ITL1.SysNumber -- ITL1.MdAbsEntry = OBTN.AbsEntry
 
  WHERE ORDR.CANCELED != 'Y' AND ORDR.DocStatus != 'O'
  AND RDR1.ShipDate > dateadd(month, -6, GETDATE())
 
 
  UNION ALL
 
 
  SELECT 
    --ORDR.DocEntry 'Order DB reference',
    --'2' 'Query Bloc',
    ORDR.DocNum 'Order number',  
    ODLN.DocNum 'Delivery number',
    OINV.DocNum 'Invoice number',
    OBTN.DistNumber 'Lot number',
    OINV.CardCode 'Costumer code',
    OINV.CardName 'Customer name',
    RDR1.ItemCode 'Product code',
    RDR1.Dscription 'Product description',
    OITL.DocDate 'Transaction log date',
    RDR1.ShipDate,
    RDR1.Quantity 'Ordered qty',
    ISNULL(DLN1.Quantity,0) 'Delivered qty' ,
    INV1.Quantity 'Invoiced quantity',
    ITL1.Quantity 'Lot quantity',
    INV1.Price 'Invoiced unit price',
    'Open' 'Order status'
    --ITL1.LogEntry 'log details reference'
    --,OITL.*
  from ORDR 
  INNER JOIN RDR1  on ORDR.DocEntry=RDR1.DocEntry AND RDR1.ItemCode != 'PAL'
  LEFT JOIN DLN1 on DLN1.BaseEntry=RDR1.DocEntry AND DLN1.ItemCode = RDR1.ItemCode
  LEFT JOIN ODLN ON ODLN.DocEntry=DLN1.DocEntry 
  LEFT JOIN INV1 ON INV1.BaseEntry = RDR1.TrgetEntry AND INV1.ItemCode = RDR1.ItemCode AND RDR1.WhsCode = INV1.WhsCode
  LEFT JOIN OINV ON OINV.DocEntry = INV1.DocEntry
  LEFT JOIN OITL ON OITL.DocEntry = INV1.BaseEntry  AND OITL.ItemCode = INV1.ItemCode AND OITL.StockEff = 1 AND OITL.DefinedQty != 0 AND OITL.ApplyType = '15' --OITL.DocEntry = INV1.BaseEntry 
  LEFT JOIN ITL1 ON OITL.LogEntry = ITL1.LogEntry 
  LEFT JOIN OBTN ON OBTN.Itemcode = ITL1.ItemCode AND OBTN.SysNumber = ITL1.SysNumber -- ITL1.MdAbsEntry = OBTN.AbsEntry
 
  WHERE ORDR.CANCELED != 'Y' AND ORDR.DocStatus = 'O'
  AND RDR1.ShipDate > dateadd(month, -6, GETDATE())
 
 
 
  UNION ALL
 
 
  SELECT 
    --ORDR.DocEntry 'Order DB reference',
    --'3' 'Query Bloc',
    ORDR.DocNum 'Order number',  
    ODLN.DocNum 'Delivery number',
    OINV.DocNum 'Invoice number',
    OBTN.DistNumber 'Lot number',
    OINV.CardCode 'Costumer code',
    OINV.CardName 'Customer name',
    RDR1.ItemCode 'Product code',
    RDR1.Dscription 'Product description',
    OITL.DocDate 'Transaction log date',
    RDR1.ShipDate,
    RDR1.Quantity 'Ordered qty',
    ISNULL(DLN1.Quantity,0) 'Delivered qty' ,
    INV1.Quantity 'Invoiced quantity',
    ITL1.Quantity 'Lot quantity',
    INV1.Price 'Invoiced unit price',
    'Closed' 'Order status'
    --ITL1.LogEntry 'log details reference'
    --,OITL.*
  from ORDR 
  INNER JOIN RDR1  on ORDR.DocEntry=RDR1.DocEntry AND RDR1.ItemCode != 'PAL' AND RDR1.BaseEntry IS NULL
  LEFT JOIN DLN1 on DLN1.BaseEntry=RDR1.DocEntry AND DLN1.ItemCode = RDR1.ItemCode
  LEFT JOIN ODLN ON ODLN.DocEntry=DLN1.DocEntry 
  INNER JOIN OINV ON OINV.NumAtCard = ORDR.NumAtCard AND OINV.NumAtCard IS NOT NULL AND OINV.NumAtCard != ''
  LEFT JOIN INV1 ON INV1.DocEntry = OINV.DocEntry AND INV1.ItemCode = RDR1.ItemCode AND RDR1.WhsCode = INV1.WhsCode
  LEFT JOIN OITL ON OITL.DocEntry = INV1.BaseEntry  AND OITL.ItemCode = INV1.ItemCode AND OITL.StockEff = 1 AND OITL.DefinedQty != 0 AND OITL.ApplyType = '15'--OITL.DocEntry = INV1.BaseEntry 
  LEFT JOIN ITL1 ON OITL.LogEntry = ITL1.LogEntry 
  LEFT JOIN OBTN ON OBTN.Itemcode = ITL1.ItemCode AND OBTN.SysNumber = ITL1.SysNumber -- ITL1.MdAbsEntry = OBTN.AbsEntry
 
  WHERE ORDR.CANCELED != 'Y' AND ORDR.DocStatus != 'O' AND ORDR.NumAtCard IS NOT NULL 
  AND RDR1.ShipDate > dateadd(month, -6, GETDATE())
 
 
) T0
 
ORDER BY T0.[Order status] ASC, T0.[Order number] ASC, T0.[Costumer code]
  
 
 
GO
