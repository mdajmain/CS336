-- MySQL dump 10.13  Distrib 8.4.0, for macos13.2 (arm64)
--
-- Host: localhost    Database: buyme
-- ------------------------------------------------------
-- Server version	8.0.44

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Temporary view structure for view `active_auctions`
--

DROP TABLE IF EXISTS `active_auctions`;
/*!50001 DROP VIEW IF EXISTS `active_auctions`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `active_auctions` AS SELECT 
 1 AS `auctionID`,
 1 AS `currentPrice`,
 1 AS `closeDateTime`,
 1 AS `bidIncrement`,
 1 AS `itemName`,
 1 AS `description`,
 1 AS `itemCondition`,
 1 AS `sellerName`,
 1 AS `bidCount`*/;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `admin`
--

DROP TABLE IF EXISTS `admin`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `admin` (
  `adminID` int NOT NULL AUTO_INCREMENT,
  `userID` int NOT NULL,
  PRIMARY KEY (`adminID`),
  UNIQUE KEY `userID` (`userID`),
  CONSTRAINT `admin_ibfk_1` FOREIGN KEY (`userID`) REFERENCES `user` (`userID`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `admin`
--

LOCK TABLES `admin` WRITE;
/*!40000 ALTER TABLE `admin` DISABLE KEYS */;
INSERT INTO `admin` VALUES (1,1);
/*!40000 ALTER TABLE `admin` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `alert`
--

DROP TABLE IF EXISTS `alert`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `alert` (
  `alertID` int NOT NULL AUTO_INCREMENT,
  `userID` int NOT NULL,
  `itemName` varchar(255) DEFAULT NULL,
  `categoryID` int DEFAULT NULL,
  `minPrice` decimal(10,2) DEFAULT NULL,
  `maxPrice` decimal(10,2) DEFAULT NULL,
  `isActive` tinyint(1) DEFAULT '1',
  `createdDate` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`alertID`),
  KEY `idx_user_active` (`userID`,`isActive`),
  KEY `idx_category` (`categoryID`),
  CONSTRAINT `alert_ibfk_1` FOREIGN KEY (`userID`) REFERENCES `end_user` (`userID`) ON DELETE CASCADE,
  CONSTRAINT `alert_ibfk_2` FOREIGN KEY (`categoryID`) REFERENCES `category` (`categoryID`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `alert`
--

LOCK TABLES `alert` WRITE;
/*!40000 ALTER TABLE `alert` DISABLE KEYS */;
INSERT INTO `alert` VALUES (1,3,'BMW',1,4000.00,20000.00,1,'2025-12-08 00:41:43');
/*!40000 ALTER TABLE `alert` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `auction`
--

DROP TABLE IF EXISTS `auction`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `auction` (
  `auctionID` int NOT NULL AUTO_INCREMENT,
  `itemID` int NOT NULL,
  `sellerID` int NOT NULL,
  `initialPrice` decimal(10,2) NOT NULL DEFAULT '0.01',
  `bidIncrement` decimal(10,2) NOT NULL DEFAULT '0.50',
  `reservePrice` decimal(10,2) DEFAULT NULL,
  `currentPrice` decimal(10,2) NOT NULL,
  `startDateTime` datetime NOT NULL,
  `closeDateTime` datetime NOT NULL,
  `status` enum('pending','active','closed','cancelled') DEFAULT 'pending',
  `winnerID` int DEFAULT NULL,
  PRIMARY KEY (`auctionID`),
  KEY `itemID` (`itemID`),
  KEY `winnerID` (`winnerID`),
  KEY `idx_status` (`status`,`closeDateTime`),
  KEY `idx_seller` (`sellerID`),
  KEY `idx_dates` (`startDateTime`,`closeDateTime`),
  CONSTRAINT `auction_ibfk_1` FOREIGN KEY (`itemID`) REFERENCES `item` (`itemID`),
  CONSTRAINT `auction_ibfk_2` FOREIGN KEY (`sellerID`) REFERENCES `end_user` (`userID`),
  CONSTRAINT `auction_ibfk_3` FOREIGN KEY (`winnerID`) REFERENCES `end_user` (`userID`),
  CONSTRAINT `auction_chk_1` CHECK ((`closeDateTime` > `startDateTime`)),
  CONSTRAINT `auction_chk_2` CHECK ((`bidIncrement` > 0)),
  CONSTRAINT `auction_chk_3` CHECK ((`initialPrice` >= 0))
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `auction`
--

LOCK TABLES `auction` WRITE;
/*!40000 ALTER TABLE `auction` DISABLE KEYS */;
INSERT INTO `auction` VALUES (1,1,3,20000.00,250.00,22000.00,24250.00,'2025-11-20 11:55:00','2025-11-20 20:43:38','cancelled',NULL),(2,2,3,25000.00,250.00,28000.00,25000.00,'2025-11-20 12:00:00','2025-11-26 07:00:00','closed',NULL),(3,3,3,5000.00,200.00,4000.00,5000.00,'2025-11-21 00:41:00','2025-11-29 00:41:00','cancelled',NULL),(4,4,3,7000.00,500.00,11000.00,30000.00,'2025-11-21 01:42:00','2025-11-22 01:42:00','closed',7),(5,5,7,40000.00,1000.00,60000.00,40000.00,'2025-12-04 02:46:00','2025-12-07 02:46:00','cancelled',NULL);
/*!40000 ALTER TABLE `auction` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `check_alerts_on_auction` AFTER INSERT ON `auction` FOR EACH ROW BEGIN
    DECLARE v_itemName VARCHAR(255);
    DECLARE v_categoryID INT;
    DECLARE v_subcategoryID INT;
    
    SELECT itemName, categoryID, subcategoryID 
    INTO v_itemName, v_categoryID, v_subcategoryID
    FROM item WHERE itemID = NEW.itemID;
    
    -- Notify users with matching alerts
    INSERT INTO notification (userID, message, type, relatedAuctionID)
    SELECT DISTINCT
        a.userID,
        CONCAT('New auction matches your alert: ', v_itemName),
        'alert_item',
        NEW.auctionID
    FROM alert a
    WHERE a.isActive = TRUE
        AND (a.itemName IS NULL OR v_itemName LIKE CONCAT('%', a.itemName, '%'))
        AND (a.categoryID IS NULL OR a.categoryID = v_categoryID OR a.categoryID = v_subcategoryID)
        AND (a.minPrice IS NULL OR NEW.initialPrice >= a.minPrice)
        AND (a.maxPrice IS NULL OR NEW.initialPrice <= a.maxPrice);
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `activate_auction` BEFORE UPDATE ON `auction` FOR EACH ROW BEGIN
    IF NEW.status = 'pending' AND NEW.startDateTime <= NOW() THEN
        SET NEW.status = 'active';
        SET NEW.currentPrice = NEW.initialPrice;
    END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `bid`
--

DROP TABLE IF EXISTS `bid`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `bid` (
  `bidID` int NOT NULL AUTO_INCREMENT,
  `auctionID` int NOT NULL,
  `buyerID` int NOT NULL,
  `bidAmount` decimal(10,2) NOT NULL,
  `maxBidLimit` decimal(10,2) NOT NULL,
  `bidTime` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `isWinning` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`bidID`),
  UNIQUE KEY `unique_auction_buyer` (`auctionID`,`buyerID`),
  KEY `idx_auction_winning` (`auctionID`,`isWinning`),
  KEY `idx_buyer` (`buyerID`),
  KEY `idx_auction_time` (`auctionID`,`bidTime` DESC),
  CONSTRAINT `bid_ibfk_1` FOREIGN KEY (`auctionID`) REFERENCES `auction` (`auctionID`),
  CONSTRAINT `bid_ibfk_2` FOREIGN KEY (`buyerID`) REFERENCES `end_user` (`userID`),
  CONSTRAINT `bid_chk_1` CHECK ((`maxBidLimit` >= `bidAmount`))
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `bid`
--

LOCK TABLES `bid` WRITE;
/*!40000 ALTER TABLE `bid` DISABLE KEYS */;
INSERT INTO `bid` VALUES (1,1,7,24250.00,25000.00,'2025-11-21 01:17:35',1),(2,4,7,30000.00,30000.00,'2025-11-21 02:28:07',1);
/*!40000 ALTER TABLE `bid` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `bid_history`
--

DROP TABLE IF EXISTS `bid_history`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `bid_history` (
  `historyID` int NOT NULL AUTO_INCREMENT,
  `auctionID` int NOT NULL,
  `buyerID` int NOT NULL,
  `bidAmount` decimal(10,2) NOT NULL,
  `actualBid` decimal(10,2) NOT NULL,
  `bidTime` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `wasWinning` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`historyID`),
  KEY `idx_auction_history` (`auctionID`,`bidTime` DESC),
  KEY `idx_buyer_history` (`buyerID`),
  CONSTRAINT `bid_history_ibfk_1` FOREIGN KEY (`auctionID`) REFERENCES `auction` (`auctionID`),
  CONSTRAINT `bid_history_ibfk_2` FOREIGN KEY (`buyerID`) REFERENCES `end_user` (`userID`)
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `bid_history`
--

LOCK TABLES `bid_history` WRITE;
/*!40000 ALTER TABLE `bid_history` DISABLE KEYS */;
INSERT INTO `bid_history` VALUES (1,1,7,20250.00,25000.00,'2025-11-21 01:17:35',0),(3,4,7,7500.00,20000.00,'2025-11-21 01:53:32',0),(5,4,7,21000.00,28000.00,'2025-11-21 01:54:48',0),(6,4,7,26000.00,28000.00,'2025-11-21 01:55:08',0),(7,4,7,30000.00,30000.00,'2025-11-21 02:28:07',0);
/*!40000 ALTER TABLE `bid_history` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `category`
--

DROP TABLE IF EXISTS `category`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `category` (
  `categoryID` int NOT NULL AUTO_INCREMENT,
  `categoryName` varchar(100) NOT NULL,
  `parentCategoryID` int DEFAULT NULL,
  `level` int NOT NULL,
  `requiredFields` text,
  PRIMARY KEY (`categoryID`),
  KEY `idx_parent` (`parentCategoryID`),
  KEY `idx_level` (`level`),
  CONSTRAINT `category_ibfk_1` FOREIGN KEY (`parentCategoryID`) REFERENCES `category` (`categoryID`),
  CONSTRAINT `category_chk_1` CHECK ((`level` between 1 and 3))
) ENGINE=InnoDB AUTO_INCREMENT=18 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `category`
--

LOCK TABLES `category` WRITE;
/*!40000 ALTER TABLE `category` DISABLE KEYS */;
INSERT INTO `category` VALUES (1,'Vehicles',NULL,1,NULL),(2,'Electronics',NULL,1,NULL),(3,'Clothing',NULL,1,NULL),(4,'Cars',1,2,NULL),(5,'Motorcycles',1,2,NULL),(6,'Trucks',1,2,NULL),(7,'Computers',2,2,NULL),(8,'Phones',2,2,NULL),(9,'Men',3,2,NULL),(10,'Women',3,2,NULL),(11,'SUVs',4,3,'[\"make\", \"model\", \"year\", \"mileage\", \"color\", \"transmission\"]'),(12,'Sedans',4,3,'[\"make\", \"model\", \"year\", \"mileage\", \"color\", \"transmission\"]'),(13,'Sports Cars',4,3,'[\"make\", \"model\", \"year\", \"mileage\", \"color\", \"transmission\"]'),(14,'Sport Bikes',5,3,'[\"make\", \"model\", \"year\", \"mileage\", \"engine_size\"]'),(15,'Cruisers',5,3,'[\"make\", \"model\", \"year\", \"mileage\", \"engine_size\"]'),(16,'Pickup Trucks',6,3,'[\"make\", \"model\", \"year\", \"mileage\", \"bed_size\", \"towing_capacity\"]'),(17,'Commercial Trucks',6,3,'[\"make\", \"model\", \"year\", \"mileage\", \"weight_class\", \"cargo_capacity\"]');
/*!40000 ALTER TABLE `category` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `customer_rep`
--

DROP TABLE IF EXISTS `customer_rep`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `customer_rep` (
  `repID` int NOT NULL AUTO_INCREMENT,
  `userID` int NOT NULL,
  `department` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`repID`),
  UNIQUE KEY `userID` (`userID`),
  CONSTRAINT `customer_rep_ibfk_1` FOREIGN KEY (`userID`) REFERENCES `user` (`userID`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `customer_rep`
--

LOCK TABLES `customer_rep` WRITE;
/*!40000 ALTER TABLE `customer_rep` DISABLE KEYS */;
INSERT INTO `customer_rep` VALUES (1,2,'General Support'),(3,10,'Billing');
/*!40000 ALTER TABLE `customer_rep` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `end_user`
--

DROP TABLE IF EXISTS `end_user`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `end_user` (
  `userID` int NOT NULL,
  `firstName` varchar(50) DEFAULT NULL,
  `lastName` varchar(50) DEFAULT NULL,
  `address` varchar(255) DEFAULT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `isAnonymous` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`userID`),
  CONSTRAINT `end_user_ibfk_1` FOREIGN KEY (`userID`) REFERENCES `user` (`userID`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `end_user`
--

LOCK TABLES `end_user` WRITE;
/*!40000 ALTER TABLE `end_user` DISABLE KEYS */;
INSERT INTO `end_user` VALUES (3,'Test','User','123 Test St','1234567890',0),(7,'test','user3','22 Jump Street','78990',0);
/*!40000 ALTER TABLE `end_user` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `item`
--

DROP TABLE IF EXISTS `item`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `item` (
  `itemID` int NOT NULL AUTO_INCREMENT,
  `categoryID` int NOT NULL,
  `subcategoryID` int NOT NULL,
  `itemName` varchar(255) NOT NULL,
  `description` text,
  `itemCondition` enum('New','Like New','Very Good','Good','Acceptable') DEFAULT 'Good',
  PRIMARY KEY (`itemID`),
  KEY `idx_category` (`categoryID`),
  KEY `idx_subcategory` (`subcategoryID`),
  KEY `idx_name` (`itemName`),
  CONSTRAINT `item_ibfk_1` FOREIGN KEY (`categoryID`) REFERENCES `category` (`categoryID`),
  CONSTRAINT `item_ibfk_2` FOREIGN KEY (`subcategoryID`) REFERENCES `category` (`categoryID`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `item`
--

LOCK TABLES `item` WRITE;
/*!40000 ALTER TABLE `item` DISABLE KEYS */;
INSERT INTO `item` VALUES (1,1,1,'Hyundai  elantra','kk','Like New'),(2,1,1,'honda civic','2025 model','New'),(3,1,1,'Hyundai  elantra','kk','New'),(4,1,1,'honda civic','uuiui','Very Good'),(5,1,1,'BMW  X6','ALL NEW CONDITION','Like New');
/*!40000 ALTER TABLE `item` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `item_field`
--

DROP TABLE IF EXISTS `item_field`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `item_field` (
  `fieldID` int NOT NULL AUTO_INCREMENT,
  `itemID` int NOT NULL,
  `fieldName` varchar(100) NOT NULL,
  `fieldValue` varchar(500) DEFAULT NULL,
  PRIMARY KEY (`fieldID`),
  UNIQUE KEY `unique_item_field` (`itemID`,`fieldName`),
  KEY `idx_item` (`itemID`),
  CONSTRAINT `item_field_ibfk_1` FOREIGN KEY (`itemID`) REFERENCES `item` (`itemID`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `item_field`
--

LOCK TABLES `item_field` WRITE;
/*!40000 ALTER TABLE `item_field` DISABLE KEYS */;
/*!40000 ALTER TABLE `item_field` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `notification`
--

DROP TABLE IF EXISTS `notification`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `notification` (
  `notificationID` int NOT NULL AUTO_INCREMENT,
  `userID` int NOT NULL,
  `message` text NOT NULL,
  `type` enum('outbid','auction_won','auction_ended','alert_item','bid_exceeded') NOT NULL,
  `relatedAuctionID` int DEFAULT NULL,
  `isRead` tinyint(1) DEFAULT '0',
  `createdTime` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`notificationID`),
  KEY `relatedAuctionID` (`relatedAuctionID`),
  KEY `idx_user_unread` (`userID`,`isRead`),
  KEY `idx_created` (`createdTime` DESC),
  CONSTRAINT `notification_ibfk_1` FOREIGN KEY (`userID`) REFERENCES `user` (`userID`) ON DELETE CASCADE,
  CONSTRAINT `notification_ibfk_2` FOREIGN KEY (`relatedAuctionID`) REFERENCES `auction` (`auctionID`)
) ENGINE=InnoDB AUTO_INCREMENT=24 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `notification`
--

LOCK TABLES `notification` WRITE;
/*!40000 ALTER TABLE `notification` DISABLE KEYS */;
INSERT INTO `notification` VALUES (2,7,'Congratulations! You won the auction for Hyundai  elantra','auction_won',1,1,'2025-11-21 01:43:38'),(3,3,'Your item Hyundai  elantra has been sold!','auction_ended',1,1,'2025-11-21 01:43:38'),(4,7,'You have been outbid!','outbid',4,1,'2025-11-21 01:54:14'),(6,7,'Congratulations! You won the auction for honda civic','auction_won',4,0,'2025-11-22 06:42:48'),(7,3,'Your item honda civic has been sold!','auction_ended',4,1,'2025-11-22 06:42:48'),(8,3,'Your question \'email address\' has been answered by customer support.','alert_item',NULL,1,'2025-11-26 04:54:38'),(9,3,'Your question \'email address\' has been answered by customer support.','alert_item',NULL,1,'2025-11-26 04:54:40'),(10,3,'Your question \'email address\' has been answered by customer support.','alert_item',NULL,1,'2025-11-26 04:55:44'),(11,3,'Your auction for honda civic ended without meeting reserve price','auction_ended',2,1,'2025-11-26 12:25:45'),(12,7,'Your auction for BMW  X6 ended without meeting reserve price','auction_ended',5,0,'2025-12-07 07:46:48'),(14,3,'Your question \'change password\' has been answered by customer support.','alert_item',NULL,1,'2025-12-08 00:42:49'),(16,3,'Your auction for \'Hyundai  elantra\' has been removed by a customer representative. Reason: demo','auction_ended',1,1,'2025-12-08 01:57:40'),(17,7,'An auction you were bidding on (\'Hyundai  elantra\') has been removed. Reason: demo','auction_ended',1,0,'2025-12-08 01:57:40'),(21,7,'Your auction for \'BMW  X6\' has been removed by a customer representative. Reason: demo','auction_ended',5,0,'2025-12-08 02:20:50');
/*!40000 ALTER TABLE `notification` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `question`
--

DROP TABLE IF EXISTS `question`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `question` (
  `questionID` int NOT NULL AUTO_INCREMENT,
  `userID` int NOT NULL,
  `repID` int DEFAULT NULL,
  `auctionID` int DEFAULT NULL,
  `subject` varchar(255) DEFAULT NULL,
  `message` text NOT NULL,
  `answer` text,
  `status` enum('open','answered','closed') DEFAULT 'open',
  `createdTime` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `answeredTime` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`questionID`),
  KEY `repID` (`repID`),
  KEY `auctionID` (`auctionID`),
  KEY `idx_status` (`status`),
  KEY `idx_user` (`userID`),
  CONSTRAINT `question_ibfk_1` FOREIGN KEY (`userID`) REFERENCES `user` (`userID`),
  CONSTRAINT `question_ibfk_2` FOREIGN KEY (`repID`) REFERENCES `customer_rep` (`repID`),
  CONSTRAINT `question_ibfk_3` FOREIGN KEY (`auctionID`) REFERENCES `auction` (`auctionID`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `question`
--

LOCK TABLES `question` WRITE;
/*!40000 ALTER TABLE `question` DISABLE KEYS */;
INSERT INTO `question` VALUES (1,3,1,NULL,'email address','can i change my email address','Sorry for that you got to create a new account\r\nWe dont approve of that.','closed','2025-11-22 01:24:53','2025-11-26 04:55:44'),(2,3,1,NULL,'change password','how can I change my password','its in your profile management.','answered','2025-12-08 00:42:17','2025-12-08 00:42:49');
/*!40000 ALTER TABLE `question` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sales_report`
--

DROP TABLE IF EXISTS `sales_report`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sales_report` (
  `reportID` int NOT NULL AUTO_INCREMENT,
  `auctionID` int NOT NULL,
  `itemID` int NOT NULL,
  `itemName` varchar(255) NOT NULL,
  `categoryID` int NOT NULL,
  `buyerID` int NOT NULL,
  `sellerID` int NOT NULL,
  `finalPrice` decimal(10,2) NOT NULL,
  `reserveMet` tinyint(1) DEFAULT '1',
  `transactionDate` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`reportID`),
  UNIQUE KEY `auctionID` (`auctionID`),
  KEY `itemID` (`itemID`),
  KEY `idx_date` (`transactionDate`),
  KEY `idx_seller` (`sellerID`),
  KEY `idx_buyer` (`buyerID`),
  KEY `idx_category` (`categoryID`),
  CONSTRAINT `sales_report_ibfk_1` FOREIGN KEY (`auctionID`) REFERENCES `auction` (`auctionID`),
  CONSTRAINT `sales_report_ibfk_2` FOREIGN KEY (`itemID`) REFERENCES `item` (`itemID`),
  CONSTRAINT `sales_report_ibfk_3` FOREIGN KEY (`categoryID`) REFERENCES `category` (`categoryID`),
  CONSTRAINT `sales_report_ibfk_4` FOREIGN KEY (`buyerID`) REFERENCES `end_user` (`userID`),
  CONSTRAINT `sales_report_ibfk_5` FOREIGN KEY (`sellerID`) REFERENCES `end_user` (`userID`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sales_report`
--

LOCK TABLES `sales_report` WRITE;
/*!40000 ALTER TABLE `sales_report` DISABLE KEYS */;
INSERT INTO `sales_report` VALUES (1,1,1,'Hyundai  elantra',1,7,3,24250.00,1,'2025-11-21 01:43:38'),(2,4,4,'honda civic',1,7,3,30000.00,1,'2025-11-22 06:42:48');
/*!40000 ALTER TABLE `sales_report` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Temporary view structure for view `similar_items`
--

DROP TABLE IF EXISTS `similar_items`;
/*!50001 DROP VIEW IF EXISTS `similar_items`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `similar_items` AS SELECT 
 1 AS `currentAuction`,
 1 AS `similarAuction`,
 1 AS `itemName`,
 1 AS `currentPrice`,
 1 AS `closeDateTime`*/;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `user`
--

DROP TABLE IF EXISTS `user`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user` (
  `userID` int NOT NULL AUTO_INCREMENT,
  `username` varchar(50) NOT NULL,
  `password` varchar(255) NOT NULL,
  `email` varchar(100) NOT NULL,
  `userType` enum('end_user','customer_rep','admin') NOT NULL,
  `createdDate` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `isSuspended` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`userID`),
  UNIQUE KEY `username` (`username`),
  UNIQUE KEY `email` (`email`),
  KEY `idx_username` (`username`),
  KEY `idx_email` (`email`),
  KEY `idx_suspended` (`isSuspended`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user`
--

LOCK TABLES `user` WRITE;
/*!40000 ALTER TABLE `user` DISABLE KEYS */;
INSERT INTO `user` VALUES (1,'admin','$2a$10$m.wfQTC/FUDPA6IEIsDf/.AlF8dQvV34uK5PzAIWq.Asvo8SLMR3K','admin@buyme.com','admin','2025-11-19 03:09:48',0),(2,'rep1','$2a$10$UDgajVCn9XBdlKCmLPI7NeuUNAE3xs5XkRNrvA1vGEh0n/x0gNT0i','rep1@buyme.com','customer_rep','2025-11-19 03:09:48',0),(3,'testuser','$2a$10$rrnfB6xJnspEmE/gsUODkO7LhkelFR8M0XHlmZa32y9BLSdOTkUO6','test@buyme.com','end_user','2025-11-19 05:53:14',0),(7,'testuser3','$2a$10$GtDWtWuTdGgD2iZ7L..QfeQjAN4uAVcSckUXGQ.iU37nFgkpCoHa.','testuser3@gmail.com','end_user','2025-11-21 01:16:46',0),(10,'rep22','$2a$10$WzVLUtxvHMkmTUajRkPpnemiTHi4uBIQnV7rvPW89r9XzIVKpCFc.','rep123@gmail.com','customer_rep','2025-12-08 00:43:41',0);
/*!40000 ALTER TABLE `user` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Temporary view structure for view `user_bidding_history`
--

DROP TABLE IF EXISTS `user_bidding_history`;
/*!50001 DROP VIEW IF EXISTS `user_bidding_history`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `user_bidding_history` AS SELECT 
 1 AS `buyerID`,
 1 AS `username`,
 1 AS `auctionID`,
 1 AS `itemName`,
 1 AS `bidAmount`,
 1 AS `bidTime`,
 1 AS `auctionStatus`,
 1 AS `bidStatus`*/;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `user_suspension_log`
--

DROP TABLE IF EXISTS `user_suspension_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_suspension_log` (
  `logID` int NOT NULL AUTO_INCREMENT,
  `userID` int NOT NULL,
  `suspendedBy` int NOT NULL,
  `action` enum('suspended','unsuspended') NOT NULL,
  `reason` text,
  `actionDate` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`logID`),
  KEY `suspendedBy` (`suspendedBy`),
  KEY `idx_user` (`userID`),
  KEY `idx_date` (`actionDate` DESC),
  CONSTRAINT `user_suspension_log_ibfk_1` FOREIGN KEY (`userID`) REFERENCES `user` (`userID`) ON DELETE CASCADE,
  CONSTRAINT `user_suspension_log_ibfk_2` FOREIGN KEY (`suspendedBy`) REFERENCES `user` (`userID`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_suspension_log`
--

LOCK TABLES `user_suspension_log` WRITE;
/*!40000 ALTER TABLE `user_suspension_log` DISABLE KEYS */;
/*!40000 ALTER TABLE `user_suspension_log` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping events for database 'buyme'
--
/*!50106 SET @save_time_zone= @@TIME_ZONE */ ;
/*!50106 DROP EVENT IF EXISTS `close_auctions_event` */;
DELIMITER ;;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;;
/*!50003 SET character_set_client  = utf8mb4 */ ;;
/*!50003 SET character_set_results = utf8mb4 */ ;;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;;
/*!50003 SET @saved_time_zone      = @@time_zone */ ;;
/*!50003 SET time_zone             = 'SYSTEM' */ ;;
/*!50106 CREATE*/ /*!50117 DEFINER=`root`@`localhost`*/ /*!50106 EVENT `close_auctions_event` ON SCHEDULE EVERY 1 MINUTE STARTS '2025-11-18 22:09:48' ON COMPLETION NOT PRESERVE ENABLE DO BEGIN
    CALL close_expired_auctions();
END */ ;;
/*!50003 SET time_zone             = @saved_time_zone */ ;;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;;
/*!50003 SET character_set_client  = @saved_cs_client */ ;;
/*!50003 SET character_set_results = @saved_cs_results */ ;;
/*!50003 SET collation_connection  = @saved_col_connection */ ;;
DELIMITER ;
/*!50106 SET TIME_ZONE= @save_time_zone */ ;

--
-- Dumping routines for database 'buyme'
--
/*!50003 DROP PROCEDURE IF EXISTS `close_expired_auctions` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `close_expired_auctions`()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_auctionID INT;
    DECLARE v_winnerID INT;
    DECLARE v_sellerID INT;
    DECLARE v_itemID INT;
    DECLARE v_itemName VARCHAR(255);
    DECLARE v_categoryID INT;
    DECLARE v_finalPrice DECIMAL(10,2);
    DECLARE v_reservePrice DECIMAL(10,2);
    
    DECLARE cur CURSOR FOR 
        SELECT auctionID, winnerID, sellerID, itemID, currentPrice, reservePrice
        FROM auction 
        WHERE status = 'active' AND closeDateTime <= NOW();
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    OPEN cur;
    
    read_loop: LOOP
        FETCH cur INTO v_auctionID, v_winnerID, v_sellerID, v_itemID, v_finalPrice, v_reservePrice;
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        -- Update auction status
        UPDATE auction SET status = 'closed' WHERE auctionID = v_auctionID;
        
        -- Get item details
        SELECT itemName, categoryID INTO v_itemName, v_categoryID
        FROM item WHERE itemID = v_itemID;
        
        -- If there's a winner and reserve is met
        IF v_winnerID IS NOT NULL AND (v_reservePrice IS NULL OR v_finalPrice >= v_reservePrice) THEN
            -- Create sales report
            INSERT INTO sales_report (auctionID, itemID, itemName, categoryID, buyerID, sellerID, finalPrice, reserveMet)
            VALUES (v_auctionID, v_itemID, v_itemName, v_categoryID, v_winnerID, v_sellerID, v_finalPrice, TRUE);
            
            -- Notify winner
            INSERT INTO notification (userID, message, type, relatedAuctionID)
            VALUES (v_winnerID, CONCAT('Congratulations! You won the auction for ', v_itemName), 'auction_won', v_auctionID);
            
            -- Notify seller
            INSERT INTO notification (userID, message, type, relatedAuctionID)
            VALUES (v_sellerID, CONCAT('Your item ', v_itemName, ' has been sold!'), 'auction_ended', v_auctionID);
        ELSE
            -- Notify seller that auction ended without sale
            INSERT INTO notification (userID, message, type, relatedAuctionID)
            VALUES (v_sellerID, CONCAT('Your auction for ', v_itemName, ' ended without meeting reserve price'), 'auction_ended', v_auctionID);
        END IF;
    END LOOP;
    
    CLOSE cur;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `place_bid` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `place_bid`(
    IN p_auctionID INT,
    IN p_buyerID INT,
    IN p_maxBidLimit DECIMAL(10,2)
)
BEGIN
    DECLARE v_currentPrice DECIMAL(10,2);
    DECLARE v_bidIncrement DECIMAL(10,2);
    DECLARE v_currentWinnerID INT;
    DECLARE v_currentWinnerMax DECIMAL(10,2);
    DECLARE v_newBidAmount DECIMAL(10,2);
    DECLARE v_sellerID INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- Get auction details (lock the row so concurrent bids serialize)
    SELECT currentPrice, bidIncrement, winnerID, sellerID
    INTO v_currentPrice, v_bidIncrement, v_currentWinnerID, v_sellerID
    FROM auction
    WHERE auctionID = p_auctionID AND status = 'active'
    FOR UPDATE;

    -- Check if buyer is the seller
    IF p_buyerID = v_sellerID THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Sellers cannot bid on their own items';
    END IF;

    -- Calculate minimum valid bid (current + increment)
    SET v_newBidAmount = v_currentPrice + v_bidIncrement;

    -- Check if bid is high enough (must be at least min bid)
    IF p_maxBidLimit < v_newBidAmount THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Bid must be at least current price plus increment';
    END IF;

    -- If there's a current winner, get their max bid
    IF v_currentWinnerID IS NOT NULL AND v_currentWinnerID != p_buyerID THEN
        SELECT maxBidLimit INTO v_currentWinnerMax
        FROM bid
        WHERE auctionID = p_auctionID AND buyerID = v_currentWinnerID AND isWinning = TRUE;

        -- Automatic bidding logic
        IF p_maxBidLimit > v_currentWinnerMax THEN
            -- New bidder wins
            -- Current winner's bid goes to their max
            UPDATE bid
            SET isWinning = FALSE
            WHERE auctionID = p_auctionID AND isWinning = TRUE;

            -- New winner pays current winner's max + increment, but not above their own max
            SET v_newBidAmount = LEAST(v_currentWinnerMax + v_bidIncrement, p_maxBidLimit);

            -- Update or insert new bid
            INSERT INTO bid (auctionID, buyerID, bidAmount, maxBidLimit, isWinning)
            VALUES (p_auctionID, p_buyerID, v_newBidAmount, p_maxBidLimit, TRUE)
            ON DUPLICATE KEY UPDATE
                bidAmount = v_newBidAmount,
                maxBidLimit = p_maxBidLimit,
                isWinning = TRUE,
                bidTime = CURRENT_TIMESTAMP;

            -- Update auction current price
            UPDATE auction
            SET currentPrice = v_newBidAmount, winnerID = p_buyerID
            WHERE auctionID = p_auctionID;

            -- Notify outbid user
            INSERT INTO notification (userID, message, type, relatedAuctionID)
            VALUES (v_currentWinnerID, 'You have been outbid!', 'outbid', p_auctionID);

        ELSE
            -- Current winner retains lead but price increases
            SET v_newBidAmount = p_maxBidLimit + v_bidIncrement;

            IF v_newBidAmount <= v_currentWinnerMax THEN
                -- Update current winner's actual bid amount
                UPDATE bid
                SET bidAmount = v_newBidAmount
                WHERE auctionID = p_auctionID AND buyerID = v_currentWinnerID;

                -- Update auction price
                UPDATE auction
                SET currentPrice = v_newBidAmount
                WHERE auctionID = p_auctionID;

                -- Notify new bidder they were immediately outbid
                INSERT INTO notification (userID, message, type, relatedAuctionID)
                VALUES (p_buyerID, 'You have been outbid!', 'outbid', p_auctionID);
            END IF;
        END IF;
    ELSE
        -- First bid or bidder is updating their max
        -- Use the user's amount as the visible bid (they already passed the min check)
        SET v_newBidAmount = p_maxBidLimit;

        INSERT INTO bid (auctionID, buyerID, bidAmount, maxBidLimit, isWinning)
        VALUES (p_auctionID, p_buyerID, v_newBidAmount, p_maxBidLimit, TRUE)
        ON DUPLICATE KEY UPDATE
            bidAmount = v_newBidAmount,
            maxBidLimit = p_maxBidLimit,
            isWinning = TRUE,
            bidTime = CURRENT_TIMESTAMP;

        UPDATE auction
        SET currentPrice = v_newBidAmount, winnerID = p_buyerID
        WHERE auctionID = p_auctionID;
    END IF;

    -- Record in bid history (show the actual visible bid amount)
    INSERT INTO bid_history (auctionID, buyerID, bidAmount, actualBid)
    VALUES (p_auctionID, p_buyerID, v_newBidAmount, p_maxBidLimit);

    COMMIT;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Final view structure for view `active_auctions`
--

/*!50001 DROP VIEW IF EXISTS `active_auctions`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `active_auctions` AS select `a`.`auctionID` AS `auctionID`,`a`.`currentPrice` AS `currentPrice`,`a`.`closeDateTime` AS `closeDateTime`,`a`.`bidIncrement` AS `bidIncrement`,`i`.`itemName` AS `itemName`,`i`.`description` AS `description`,`i`.`itemCondition` AS `itemCondition`,`u`.`username` AS `sellerName`,(select count(0) from `bid_history` where (`bid_history`.`auctionID` = `a`.`auctionID`)) AS `bidCount` from (((`auction` `a` join `item` `i` on((`a`.`itemID` = `i`.`itemID`))) join `end_user` `e` on((`a`.`sellerID` = `e`.`userID`))) join `user` `u` on((`e`.`userID` = `u`.`userID`))) where ((`a`.`status` = 'active') and (`a`.`startDateTime` <= now()) and (`a`.`closeDateTime` > now())) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `similar_items`
--

/*!50001 DROP VIEW IF EXISTS `similar_items`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `similar_items` AS select `a1`.`auctionID` AS `currentAuction`,`a2`.`auctionID` AS `similarAuction`,`i2`.`itemName` AS `itemName`,`a2`.`currentPrice` AS `currentPrice`,`a2`.`closeDateTime` AS `closeDateTime` from (((`auction` `a1` join `item` `i1` on((`a1`.`itemID` = `i1`.`itemID`))) join `item` `i2` on((`i1`.`subcategoryID` = `i2`.`subcategoryID`))) join `auction` `a2` on((`i2`.`itemID` = `a2`.`itemID`))) where ((`a1`.`auctionID` <> `a2`.`auctionID`) and (`a2`.`status` = 'active') and (`a2`.`startDateTime` >= (now() - interval 30 day)) and ((abs((`a1`.`currentPrice` - `a2`.`currentPrice`)) / `a1`.`currentPrice`) <= 0.2)) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `user_bidding_history`
--

/*!50001 DROP VIEW IF EXISTS `user_bidding_history`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `user_bidding_history` AS select `bh`.`buyerID` AS `buyerID`,`u`.`username` AS `username`,`a`.`auctionID` AS `auctionID`,`i`.`itemName` AS `itemName`,`bh`.`bidAmount` AS `bidAmount`,`bh`.`bidTime` AS `bidTime`,`a`.`status` AS `auctionStatus`,(case when (`a`.`winnerID` = `bh`.`buyerID`) then 'Won' when (`a`.`status` = 'closed') then 'Lost' else 'Active' end) AS `bidStatus` from (((`bid_history` `bh` join `auction` `a` on((`bh`.`auctionID` = `a`.`auctionID`))) join `item` `i` on((`a`.`itemID` = `i`.`itemID`))) join `user` `u` on((`bh`.`buyerID` = `u`.`userID`))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-09-11 22:08:44
