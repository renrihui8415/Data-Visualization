use [JuliaDatabase]
go

select * from Orders_Enlargement
select * from [Order Details Enlargement]

select * from Shippers

/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
2.7 Ship Area Code Driven Sales Performance
*/
--select * from Shippers
--create index idx_Shippers_Phone on Shippers(Phone)
--create index idx_Orders_ShipVia on Orders_Enlargement(ShipVia)
USE [JuliaDatabase]
GO

IF OBJECT_ID('usp_ShippingDriven') IS NOT NULL
    DROP PROCEDURE usp_ShippingDriven
GO

CREATE PROCEDURE usp_ShippingDriven(@AreaCode_No varchar(2000) =null )
AS
BEGIN

    SET NOCOUNT ON

	Declare @sql varchar(8000)
    set @sql='
	

		select AreaCode,  SalesPerformance , CompanyName,RANK() OVER (Order by SalesPerformance Desc) RankInPopularity 
		from (
				Select AreaCode, sum(isnull (UnitPrice*Quantity*(1-Discount) ,0) ) as SalesPerformance, CompanyName
				From(

					select OrderID, Substring(phone,2,3) as AreaCode, CompanyName
					from Shippers as s inner join [Orders_Enlargement] as o 
					On s.ShipperID=o.Shipvia 
					Where '+
					Case when @AreaCode_No is not null and @AreaCode_No <>'all' 
								Then 'Substring (Phone,2,3) in (' + @AreaCode_No + ')'
						 when @AreaCode_No ='all' or @AreaCode_No is null 
								then 'Substring (Phone,2,3) is not null ' end +

					') as t inner join [Order Details Enlargement] as od
						On t.OrderID=od.OrderID
						Group by AreaCode, CompanyName

				) as tt
			Order by RankInPopularity'

	print @sql

	exec(@sql)

    SET NOCOUNT OFF

END
GO
--************************************************************************************************
--to run the SP
exec usp_ShippingDriven --sales performance for all Shippers
exec usp_ShippingDriven '901,202,203' --Sales performance for shippers whose phone area code is 901, 202, 203


/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
2.17 Popular Suppliers with products sales performance
*/
--Create index Idx_Shipvia ON Orders (Shipvia)
USE [JuliaDatabase]
GO

IF OBJECT_ID('usp_SupplierReput') IS NOT NULL
    DROP PROCEDURE usp_SupplierReput
GO

CREATE PROCEDURE usp_SupplierReput(@Rank_No int =null )
AS
BEGIN
BEGIN TRY
    SET NOCOUNT ON

	Declare @sql varchar(2000)
    set @sql='
		Select SupplierID, SupplierName, Country, TotalProductsSold,
		RANK() OVER (Order by TotalProductsSold Desc) RankInPopularity
		from 
		(
			Select t.SupplierID, CompanyName as SupplierName, Country, TotalProductsSold 
			From( 
				   
				Select ' +
				case when @Rank_No is not null
				then 'top '+ convert(varchar,@Rank_No )
				else 'top 100' end +'
				SupplierID,  Sum(od.quantity) as TotalProductsSold
				from Products as p inner join [Order Details Enlargement] as od 
				On p.ProductID=od.ProductID 
				group by SupplierID
				order by  2 desc

				) as t inner join Suppliers as s
				On t.SupplierID=s.SupplierID
		) as w'
		
	print @sql

	exec(@sql)

	--(29 rows affected)

    SET NOCOUNT OFF
END TRY
BEGIN CATCH
	PRINT(ERROR_MESSAGE())
END CATCH
END
GO
--************************************************************************************************
--to run the SP
exec usp_SupplierReput --total products sold for all Suppliers
exec usp_SupplierReput 11 --top 10 Suppliers based on total products sold