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
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `bid`
--

LOCK TABLES `bid` WRITE;
/*!40000 ALTER TABLE `bid` DISABLE KEYS */;
INSERT INTO `bid` VALUES (1,1,7,24250.00,25000.00,'2025-11-21 01:17:35',1),(2,4,7,30000.00,30000.00,'2025-11-21 02:28:07',1),(3,4,8,20500.00,25000.00,'2025-11-21 01:54:14',0);
/*!40000 ALTER TABLE `bid` ENABLE KEYS */;
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
