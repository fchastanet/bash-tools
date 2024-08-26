-- MySQL dump 10.13  Distrib 8.0.27, for Linux (x86_64)
--
-- Host: 127.0.0.1    Database: attributes
-- ------------------------------------------------------
-- Server version	8.0.16

--
-- Table structure for table `customer`
--

CREATE TABLE `customer` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  `identifier` varchar(128) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `identifier` (`identifier`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8;

--
-- Table structure for table `learner`
--

CREATE TABLE `learner` (
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `external_id` varchar(255) NOT NULL,
  `customer_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_learner_by_customer` (`external_id`,`customer_id`),
  KEY `learner_customer_id_index` (`customer_id`),
  CONSTRAINT `learner_customer_id_fk` FOREIGN KEY (`customer_id`) REFERENCES `customer` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8;

--
-- Table structure for table `learner_attribute`
--

CREATE TABLE `learner_attribute` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  `level` double NOT NULL,
  `interest` double NOT NULL,
  `learner_id` int(10) unsigned NOT NULL,
  `attribute_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`id`),
  KEY `learner_attribute_learner_id_index` (`learner_id`),
  KEY `learner_attribute_attribute_id_index` (`attribute_id`),
  CONSTRAINT `learner_attribute_learner_id_fk` FOREIGN KEY (`learner_id`) REFERENCES `learner` (`id`),
  CONSTRAINT `learner_attribute_attribute_id_fk` FOREIGN KEY (`attribute_id`) REFERENCES `attribute` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=415 DEFAULT CHARSET=utf8;

--
-- Table structure for table `attribute`
--

CREATE TABLE `attribute` (
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `translations` json NOT NULL,
  `mapped_attribute_id` int(10) unsigned DEFAULT NULL,
  `internal_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `attribute_internal_id_uniq` (`internal_id`),
  KEY `attribute_mapped_attribute_id_index` (`mapped_attribute_id`),
  CONSTRAINT `attribute_mapped_attribute_id_fk` FOREIGN KEY (`mapped_attribute_id`) REFERENCES `attribute` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=190 DEFAULT CHARSET=utf8;

--
-- Table structure for table `product`
--

CREATE TABLE `product` (
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `external_id` int(10) unsigned NOT NULL,
  `customer_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_training_by_customer` (`external_id`,`customer_id`),
  KEY `product_customer_id_index` (`customer_id`),
  CONSTRAINT `product_customer_id_fk` FOREIGN KEY (`customer_id`) REFERENCES `customer` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=27 DEFAULT CHARSET=utf8;

--
-- Table structure for table `product_attribute`
--

CREATE TABLE `product_attribute` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  `relevance` double NOT NULL,
  `attribute_id` int(10) unsigned NOT NULL,
  `training_course_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`id`),
  KEY `product_attribute_attribute_id_index` (`attribute_id`),
  KEY `products_training_course_id_index` (`training_course_id`),
  CONSTRAINT `products_training_course_id_fk` FOREIGN KEY (`training_course_id`) REFERENCES `product` (`id`),
  CONSTRAINT `product_attribute_attribute_id_fk` FOREIGN KEY (`attribute_id`) REFERENCES `attribute` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=48 DEFAULT CHARSET=utf8;


-- Dump completed on 2021-11-08 22:58:26
