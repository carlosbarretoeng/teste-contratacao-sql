-- Crie uma query que obtenha a lista de produtos (ProductName), e a quantidade por unidade (QuantityPerUnit);
SELECT ProductName, QuantityPerUnit FROM Products;

-- Crie uma query que obtenha a lista de produtos ativos (ProductID e ProductName);
SELECT ProductID, ProductName FROM Products WHERE Discontinued = 0;
 -- View Current Product List

-- Crie uma query que obtenha a lista de produtos descontinuados (ProductID e ProductName);
SELECT ProductID, ProductName FROM Products WHERE Discontinued = 1;

-- Crie uma query que obtenha a lista de produtos (ProductID, ProductName, UnitPrice) ativos, onde o custo dos produtos s�o menores que $20;
SELECT ProductID, ProductName, UnitPrice FROM Products WHERE Discontinued = 0 AND UnitPrice < 20;

-- Crie uma query que obtenha a lista de produtos (ProductID, ProductName, UnitPrice) ativos, onde o custo dos produtos s�o entre $15 e $25;
SELECT ProductID, ProductName, UnitPrice FROM Products WHERE Discontinued = 0 AND UnitPrice BETWEEN 15 AND 25;

-- Crie uma query que obtenha a lista de produtos (ProductName, UnitPrice) que tem pre�o acima da m�dia;
WITH AveragePrice AS ( SELECT AVG(UnitPrice) AS AvgPrice FROM [dbo].[Products] ) SELECT ProductName, UnitPrice FROM Products, AveragePrice WHERE UnitPrice > AvgPrice;
-- View Products Above Average Price

-- Crie uma procedure que retorne cada produto e seu pre�o;
--   Adicione � procedure, criada na quest�o anterior, os par�metros 'Codigo_Fornecedor' (permitindo escolher 1 ou mais) e 'Codigo_Categoria' 
--     (permitindo escolher 1 ou mais) e altere-a para atender a passagem desses par�metros;
--   Adicione � procedure, criada na quest�o anterior, o par�metro 'Codigo_Transportadora' (permitindo escolher 1 ou mais) e um outro 
--     par�metro 'Tipo_Saida' para se optar por uma sa�da OLTP (Transacional) ou OLAP (Pivot).

-- Crie uma query que obtenha a lista de empregados e seus liderados, caso o empregado n�o possua liderado, informar 'N�o possui liderados'.
WITH LideradoPorLider AS (
	SELECT 
		l.EmployeeID AS LiderID,
		l.FirstName + ' ' + l.LastName AS Lider,
		CASE 
			WHEN e.EmployeeID IS NULL THEN 'N�o possui liderados'
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
-- Crie uma query que obtenha a lista de pedidos dos funcion�rios da regi�o 'Western';
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
-- Crie uma query que obtenha os n�meros de pedidos e a lista de clientes (CompanyName, ContactName, Address e Phone), que possuam 171 
--   como c�digo de �rea do telefone e que o frete dos pedidos custem entre $6.00 e $13.00;
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
--   total de cada produto j� aplicado o desconto % (se tiver algum);
SELECT 
	od.OrderID, 
	p.ProductName,
	CONVERT(money,ROUND((od.UnitPrice * od.Quantity * (1 - od.Discount)/ 100 * 100), 2)) AS valorTotal
FROM [Order Details] od
JOIN Products p ON od.ProductID = p.ProductID