USE GarageFleetDB;

-- ==========================================
-- 1. DATABASE VIEWS (Summary Metrics)
-- ==========================================
-- View 1: Low Stock Alert Dashboard
CREATE VIEW vw_low_stock_alerts AS
SELECT PartID, PartName, Brand, StockQuantity 
FROM PARTS_INVENTORY 
WHERE StockQuantity < 50
ORDER BY StockQuantity ASC;

-- View 2: Mechanic Performance & Revenue Generation
CREATE VIEW vw_mechanic_revenue AS
SELECT M.MechanicID, M.Name, M.Specialization, COUNT(S.ServiceID) AS TotalServices, SUM(S.TotalCost) AS RevenueGenerated
FROM MECHANIC M
LEFT JOIN SERVICE_RECORD S ON M.MechanicID = S.MechanicID
GROUP BY M.MechanicID, M.Name, M.Specialization;

-- ==========================================
-- 2. STORED PROCEDURE (Transaction Processing)
-- ==========================================
-- Logs a new service record dynamically based on user input
DELIMITER //
CREATE PROCEDURE sp_LogNewService(
    IN p_ChassisNo VARCHAR(50), 
    IN p_MechanicID INT, 
    IN p_Odo INT, 
    IN p_Cost DECIMAL(10,2)
)
BEGIN
    INSERT INTO SERVICE_RECORD (ChassisNo, MechanicID, ServiceDate, OdometerReading, TotalCost)
    VALUES (p_ChassisNo, p_MechanicID, CURDATE(), p_Odo, p_Cost);
    
    SELECT LAST_INSERT_ID() AS 'New_ServiceID', 'Service Logged Successfully' AS 'Status';
END //
DELIMITER ;

-- ==========================================
-- 3. FUNCTIONAL TRIGGER (Dynamic Stock Update)
-- ==========================================
-- Automatically deducts stock from inventory when a mechanic logs a part used in a service
DELIMITER //
CREATE TRIGGER trg_deduct_inventory
AFTER INSERT ON SERVICE_LINE_ITEM
FOR EACH ROW
BEGIN
    UPDATE PARTS_INVENTORY
    SET StockQuantity = StockQuantity - NEW.QuantityUsed
    WHERE PartID = NEW.PartID;
END //
DELIMITER ;

-- ==========================================
-- 4. COMPLEX JOINS & CORRELATED SUBQUERIES
-- ==========================================
-- Multi-Table JOIN: Get full breakdown of a specific service invoice
SELECT SR.ServiceID, M.Model, ME.Name AS Mechanic, P.PartName, SL.QuantityUsed, P.UnitPrice
FROM SERVICE_RECORD SR
INNER JOIN MOTORCYCLE M ON SR.ChassisNo = M.ChassisNo
INNER JOIN MECHANIC ME ON SR.MechanicID = ME.MechanicID
INNER JOIN SERVICE_LINE_ITEM SL ON SR.ServiceID = SL.ServiceID
INNER JOIN PARTS_INVENTORY P ON SL.PartID = P.PartID
WHERE SR.ServiceID = 5; 

-- Correlated Subquery: Find motorcycles whose latest service cost was strictly higher than the average service cost for their specific model
SELECT SR.ChassisNo, M.Model, SR.TotalCost
FROM SERVICE_RECORD SR
JOIN MOTORCYCLE M ON SR.ChassisNo = M.ChassisNo
WHERE SR.TotalCost > (
    SELECT AVG(TotalCost)
    FROM SERVICE_RECORD SR2
    JOIN MOTORCYCLE M2 ON SR2.ChassisNo = M2.ChassisNo
    WHERE M2.Model = M.Model
);

-- ==========================================
-- 5. PERFORMANCE TUNING (EXPLAIN & INDEXING)
-- ==========================================
-- QUERY 1: Searching for high-mileage, high-cost services
EXPLAIN SELECT * FROM SERVICE_RECORD WHERE OdometerReading > 40000 AND TotalCost > 5000;
-- CREATE INDEX
CREATE INDEX idx_odo_cost ON SERVICE_RECORD(OdometerReading, TotalCost);
-- EXPLAIN AFTER INDEX (Demonstrates shift from ALL to RANGE scan)
EXPLAIN SELECT * FROM SERVICE_RECORD WHERE OdometerReading > 40000 AND TotalCost > 5000;

-- QUERY 2: Filtering inventory by Brand and Grade
EXPLAIN SELECT * FROM PARTS_INVENTORY WHERE Brand = 'Motul' AND Grade = '300V';
-- CREATE COMPOSITE INDEX
CREATE INDEX idx_brand_grade ON PARTS_INVENTORY(Brand, Grade);
-- EXPLAIN AFTER INDEX 
EXPLAIN SELECT * FROM PARTS_INVENTORY WHERE Brand = 'Motul' AND Grade = '300V';