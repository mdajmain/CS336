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
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `bid_history`
--

LOCK TABLES `bid_history` WRITE;
/*!40000 ALTER TABLE `bid_history` DISABLE KEYS */;
INSERT INTO `bid_history` VALUES (1,1,7,20250.00,25000.00,'2025-11-21 01:17:35',0),(2,1,8,20500.00,24000.00,'2025-11-21 01:19:09',0),(3,4,7,7500.00,20000.00,'2025-11-21 01:53:32',0),(4,4,8,8000.00,25000.00,'2025-11-21 01:54:14',0),(5,4,7,21000.00,28000.00,'2025-11-21 01:54:48',0),(6,4,7,26000.00,28000.00,'2025-11-21 01:55:08',0),(7,4,7,30000.00,30000.00,'2025-11-21 02:28:07',0);
/*!40000 ALTER TABLE `bid_history` ENABLE KEYS */;
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
