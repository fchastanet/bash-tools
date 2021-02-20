-- MySQL dump 10.13  Distrib 8.0.22, for Linux (x86_64)
--
-- Host: 127.0.0.1    Database: fromDb
-- ------------------------------------------------------
-- Server version       8.0.21

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
-- Dumping data for table `emptyTable`
--

DROP TABLE IF EXISTS `emptyTable`;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `emptyTable` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `modification_date` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2011640 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `emptyTable` WRITE;
/*!40000 ALTER TABLE `emptyTable` DISABLE KEYS */;
/*!40000 ALTER TABLE `emptyTable` ENABLE KEYS */;
UNLOCK TABLES;

DROP TABLE IF EXISTS `dataTable`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `dataTable` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `modification_date` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2011640 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `dataTable` WRITE;
/*!40000 ALTER TABLE `dataTable` DISABLE KEYS */;
INSERT INTO `dataTable` VALUES (1,1,'Picture:','en-GB'),(2,2,'Name:','en-GB'),(3,3,'First name:','en-GB'),(4,4,'Login:','en-GB'),(5,5,'Password:','en-GB'),(6,6,'E-mail:','en-GB'),(7,7,'Reference number:','en-GB'),(8,8,'Presentation:','en-GB'),(9,9,'Web:','en-GB'),(10,10,'Twitter:','en-GB'),(11,11,'LinkedIn:','en-GB'),(12,12,'Languages:','en-GB'),(13,13,'Time zone:','en-GB');
/*!40000 ALTER TABLE `dataTable` ENABLE KEYS */;
UNLOCK TABLES;

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `otherTable` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `modification_date` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2011640 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

LOCK TABLES `otherTable` WRITE;
/*!40000 ALTER TABLE `dataTable` DISABLE KEYS */;
INSERT INTO `otherTable` VALUES (1,1,'Picture:','en-GB'),(2,2,'Name:','en-GB'),(3,3,'First name:','en-GB'),(4,4,'Login:','en-GB'),(5,5,'Password:','en-GB'),(6,6,'E-mail:','en-GB'),(7,7,'Reference number:','en-GB'),(8,8,'Presentation:','en-GB'),(9,9,'Web:','en-GB'),(10,10,'Twitter:','en-GB'),(11,11,'LinkedIn:','en-GB'),(12,12,'Languages:','en-GB'),(13,13,'Time zone:','en-GB');
/*!40000 ALTER TABLE `dataTable` ENABLE KEYS */;
UNLOCK TABLES;


--
-- Dumping routines for database 'fromDb'
--
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2021-01-18 22:52:14
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
                                                       