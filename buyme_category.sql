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
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2025-11-20 21:58:44
