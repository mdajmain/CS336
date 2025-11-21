-- MySQL dump 10.13  Distrib 8.0.44, for macos15 (arm64)
--
-- Host: 127.0.0.1    Database: buyme
-- ------------------------------------------------------
-- Server version	8.0.44

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

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
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `auction`
--

LOCK TABLES `auction` WRITE;
/*!40000 ALTER TABLE `auction` DISABLE KEYS */;
INSERT INTO `auction` VALUES (1,1,3,20000.00,250.00,22000.00,24250.00,'2025-11-20 11:55:00','2025-11-20 20:43:38','closed',7),(2,2,3,25000.00,250.00,28000.00,25000.00,'2025-11-20 12:00:00','2025-11-26 07:00:00','pending',NULL),(3,3,3,5000.00,200.00,4000.00,5000.00,'2025-11-21 00:41:00','2025-11-29 00:41:00','cancelled',NULL),(4,4,3,7000.00,500.00,11000.00,30000.00,'2025-11-21 01:42:00','2025-11-22 01:42:00','active',7);
/*!40000 ALTER TABLE `auction` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2025-11-20 21:58:44
