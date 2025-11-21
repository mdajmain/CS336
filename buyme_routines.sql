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
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2025-11-20 21:58:44
