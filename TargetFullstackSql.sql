-- Crie uma query que obtenha a lista de produtos (ProductName), e a quantidade por unidade (QuantityPerUnit);
SELECT ProductName, QuantityPerUnit FROM Products;

-- Crie uma query que obtenha a lista de produtos ativos (ProductID e ProductName);
SELECT ProductID, ProductName FROM Products WHERE Discontinued = 0;
 -- View Current Product List

-- Crie uma query que obtenha a lista de produtos descontinuados (ProductID e ProductName);
SELECT ProductID, ProductName FROM Products WHERE Discontinued = 1;

-- Crie uma query que obtenha a lista de produtos (ProductID, ProductName, UnitPrice) ativos, onde o custo dos produtos são menores que $20;
SELECT ProductID, ProductName, UnitPrice FROM Products WHERE Discontinued = 0 AND UnitPrice < 20;

-- Crie uma query que obtenha a lista de produtos (ProductID, ProductName, UnitPrice) ativos, onde o custo dos produtos são entre $15 e $25;
SELECT ProductID, ProductName, UnitPrice FROM Products WHERE Discontinued = 0 AND UnitPrice BETWEEN 15 AND 25;

-- Crie uma query que obtenha a lista de produtos (ProductName, UnitPrice) que tem preço acima da média;
WITH AveragePrice AS ( SELECT AVG(UnitPrice) AS AvgPrice FROM [dbo].[Products] ) SELECT ProductName, UnitPrice FROM Products, AveragePrice WHERE UnitPrice > AvgPrice;
-- View Products Above Average Price

-- Crie uma procedure que retorne cada produto e seu preço;
--   Adicione à procedure, criada na questão anterior, os parâmetros 'Codigo_Fornecedor' (permitindo escolher 1 ou mais) e 'Codigo_Categoria' 
--     (permitindo escolher 1 ou mais) e altere-a para atender a passagem desses parâmetros;
--   Adicione à procedure, criada na questão anterior, o parâmetro 'Codigo_Transportadora' (permitindo escolher 1 ou mais) e um outro 
--     parâmetro 'Tipo_Saida' para se optar por uma saída OLTP (Transacional) ou OLAP (Pivot).

CREATE OR ALTER PROCEDURE sp_ProdutosPorFiltro 
    @Codigo_Fornecedor NVARCHAR(MAX) = NULL,
    @Codigo_Categoria NVARCHAR(MAX) = NULL
    -- @Codigo_Transportadora NVARCHAR(MAX) = NULL,
    -- @Tipo_Saida NVARCHAR(10) = 'OLTP'
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @FornecedorList TABLE (ID INT);
    DECLARE @CategoriaList TABLE (ID INT);
    DECLARE @TransportadoraList TABLE (ID INT);

	IF @Codigo_Fornecedor IS NOT NULL
        INSERT INTO @FornecedorList (ID)
        SELECT value FROM STRING_SPLIT(@Codigo_Fornecedor, ',');

    IF @Codigo_Categoria IS NOT NULL
        INSERT INTO @CategoriaList (ID)
        SELECT value FROM STRING_SPLIT(@Codigo_Categoria, ',');

    --IF @Codigo_Transportadora IS NOT NULL
    --    INSERT INTO @TransportadoraList (ID)
    --    SELECT value FROM STRING_SPLIT(@Codigo_Transportadora, ',');

    WITH ShippersWithProductsOrders AS (
        SELECT s.ShipperID, s.CompanyName, od.ProductId, COUNT(od.ProductId) as quant
		FROM Orders o
		JOIN Shippers s ON o.ShipVia = s.ShipperID
		JOIN [Order Details] od ON o.OrderID = od.OrderID
		GROUP BY s.ShipperID, s.CompanyName, od.ProductId
    )
	SELECT 
        p.ProductID,
        p.ProductName,
        p.UnitPrice,
		s.SupplierID,
		s.CompanyName as SupplierName,
		c.CategoryID,
		c.CategoryName,
		swpo.CompanyName,
		swpo.quant
    FROM 
        Products p
		LEFT JOIN Suppliers s ON p.SupplierID = s.SupplierID
		LEFT JOIN Categories c ON p.CategoryID = c.CategoryID
		LEFT JOIN ShippersWithProductsOrders swpo ON p.ProductID = swpo.ProductID
	WHERE
		(@Codigo_Fornecedor IS NULL OR p.SupplierID IN (SELECT ID FROM @FornecedorList)) AND
		(@Codigo_Categoria IS NULL OR p.CategoryID IN (SELECT ID FROM @CategoriaList));
END;
GO

EXECUTE sp_ProdutosPorFiltro NULL, NULL;

-- Crie uma query que obtenha a lista de empregados e seus liderados, caso o empregado não possua liderado, informar 'Não possui liderados'.
WITH LideradoPorLider AS (
	SELECT 
		l.EmployeeID AS LiderID,
		l.FirstName + ' ' + l.LastName AS Lider,
		CASE 
			WHEN e.EmployeeID IS NULL THEN 'Não possui liderados'
			ELSE e.FirstName + ' ' + e.LastName
		END AS Liderado
	FROM 
		Employees l
	LEFT JOIN
		Employees e ON e.ReportsTo = l.EmployeeID
)
SELECT LiderID, Lider, STRING_AGG(Liderado, ',')  WITHIN GROUP (ORDER BY Liderado) as Liderados 
FROM LideradoPorLider
GROUP BY LiderID, Lider
ORDER BY Lider;
-- Crie uma query que obtenha o(s) produto(s) mais caro(s) e o(s) mais barato(s) da lista (ProductName e UnitPrice);
WITH RankedProducts AS (
    SELECT 
        ProductName,
        UnitPrice,
        RANK() OVER (ORDER BY UnitPrice ASC) AS RankMaisBarato,
        RANK() OVER (ORDER BY UnitPrice DESC) AS RankMaisCaro
    FROM 
        Products
)
SELECT 
    CASE 
        WHEN RankMaisBarato = 1 THEN 'Mais Barato'
        WHEN RankMaisCaro = 1 THEN 'Mais Caro'
    END AS Tipo,
    ProductName,
    UnitPrice
FROM 
    RankedProducts
WHERE 
    RankMaisBarato = 1 OR RankMaisCaro = 1
ORDER BY 
    Tipo, UnitPrice;
-- Crie uma query que obtenha a lista de pedidos dos funcionários da região 'Western';
WITH EmployeesOnWestern AS (
	SELECT e.EmployeeID
	FROM Employees e
	JOIN EmployeeTerritories et ON e.EmployeeID = et.EmployeeID
	JOIN Territories t ON et.TerritoryID = t.TerritoryID
	JOIN Region r ON t.RegionID = r.RegionID AND r.RegionDescription = 'Western'
	GROUP BY e.EmployeeID
)
SELECT *
FROM Orders o
JOIN EmployeesOnWestern eow ON o.EmployeeID = eow.EmployeeID
-- Crie uma query que obtenha os números de pedidos e a lista de clientes (CompanyName, ContactName, Address e Phone), que possuam 171 
--   como código de área do telefone e que o frete dos pedidos custem entre $6.00 e $13.00;
WITH CustomersFromArea171 AS (
	SELECT c.CustomerID, c.CompanyName, c.ContactName, c.Address, c.Phone
	FROM Customers c
	WHERE SUBSTRING(c.Phone, 2, 3) = '171'
)
SELECT c.ContactName, c.ContactName, c.Address, c.Phone, COUNT(o.OrderID) AS numberOfOrders
FROM Orders o
JOIN CustomersFromArea171 c ON o.CustomerID = c.CustomerID
WHERE o.Freight BETWEEN 6 AND 13
GROUP BY c.ContactName, c.ContactName, c.Address, c.Phone;

-- Crie uma query que obtenha todos os dados de pedidos (Orders) que envolvam os fornecedores da cidade 'Manchester' e foram enviados 
--   pela empresa 'Speedy Express';
WITH ProductsFromManchester AS (
	SELECT ProductID
	FROM Products p
	JOIN Suppliers s ON p.SupplierID = s.SupplierID
	WHERE s.City = 'Manchester'
)
SELECT o.*
FROM Orders o
JOIN [Order Details] od ON o.OrderID = od.OrderID
JOIN ProductsFromManchester pfm ON od.ProductID = pfm.ProductID
JOIN Shippers s ON o.ShipVia = s.ShipperID
WHERE s.CompanyName = 'Speedy Express';

-- Crie uma query que obtenha a lista de Produtos (ProductName) constantes nos Detalhe dos Pedidos (Order Details), calculando o valor 
--   total de cada produto já aplicado o desconto % (se tiver algum);
SELECT 
	od.OrderID, 
	p.ProductName,
	CONVERT(money,ROUND((od.UnitPrice * od.Quantity * (1 - od.Discount)/ 100 * 100), 2)) AS valorTotal
FROM [Order Details] od
JOIN Products p ON od.ProductID = p.ProductID
