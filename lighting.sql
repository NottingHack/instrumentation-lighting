# ************************************************************
# Sequel Pro SQL dump
# Version 4541
#
# http://www.sequelpro.com/
# https://github.com/sequelpro/sequelpro
#
# Host: locutus (MySQL 5.5.5-10.0.31-MariaDB-1~jessie-wsrep)
# Database: lighting
# Generation Time: 2017-10-26 08:31:26 +0000
# ************************************************************


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;


# Dump of table buildings
# ------------------------------------------------------------

CREATE TABLE `buildings` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table floors
# ------------------------------------------------------------

CREATE TABLE `floors` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `level` int(11) NOT NULL,
  `building_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `floors_fk0` (`building_id`),
  CONSTRAINT `floors_fk0` FOREIGN KEY (`building_id`) REFERENCES `buildings` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table light_lighting_pattern
# ------------------------------------------------------------

CREATE TABLE `light_lighting_pattern` (
  `pattern_id` int(11) NOT NULL,
  `light_id` int(11) NOT NULL,
  `state` varchar(10) NOT NULL,
  PRIMARY KEY (`pattern_id`,`light_id`),
  KEY `light_lighting_pattern_fk1` (`light_id`),
  CONSTRAINT `light_lighting_pattern_fk0` FOREIGN KEY (`pattern_id`) REFERENCES `lighting_patterns` (`id`),
  CONSTRAINT `light_lighting_pattern_fk1` FOREIGN KEY (`light_id`) REFERENCES `lights` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table lighting_controllers
# ------------------------------------------------------------

CREATE TABLE `lighting_controllers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(20) NOT NULL,
  `room_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `lighting_controllers_fk0` (`room_id`),
  CONSTRAINT `lighting_controllers_fk0` FOREIGN KEY (`room_id`) REFERENCES `rooms` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table lighting_input_channels
# ------------------------------------------------------------

CREATE TABLE `lighting_input_channels` (
  `id` int(11) NOT NULL,
  `channel` int(11) NOT NULL,
  `controller_id` int(11) NOT NULL,
  `pattern_id` int(11) DEFAULT NULL,
  `statefull` int(1) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `lighting_input_channels_fk1` (`pattern_id`),
  KEY `lighting_input_channels_fk0` (`controller_id`),
  CONSTRAINT `lighting_input_channels_fk0` FOREIGN KEY (`controller_id`) REFERENCES `lighting_controllers` (`id`),
  CONSTRAINT `lighting_input_channels_fk1` FOREIGN KEY (`pattern_id`) REFERENCES `lighting_patterns` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table lighting_output_channels
# ------------------------------------------------------------

CREATE TABLE `lighting_output_channels` (
  `id` int(11) NOT NULL,
  `channel` int(11) NOT NULL,
  `controller_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `lighting_output_channels_fk0` (`controller_id`),
  CONSTRAINT `lighting_output_channels_fk0` FOREIGN KEY (`controller_id`) REFERENCES `lighting_controllers` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table lighting_patterns
# ------------------------------------------------------------

CREATE TABLE `lighting_patterns` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `next_pattern_id` int(11) DEFAULT NULL,
  `timeout` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `lighting_patterns_fk0` (`next_pattern_id`),
  CONSTRAINT `lighting_patterns_fk0` FOREIGN KEY (`next_pattern_id`) REFERENCES `lighting_patterns` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table lights
# ------------------------------------------------------------

CREATE TABLE `lights` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT '',
  `room_id` int(11) NOT NULL,
  `output_channel_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `lights_fk0` (`room_id`),
  KEY `lights_fk1` (`output_channel_id`),
  CONSTRAINT `lights_fk0` FOREIGN KEY (`room_id`) REFERENCES `rooms` (`id`),
  CONSTRAINT `lights_fk1` FOREIGN KEY (`output_channel_id`) REFERENCES `lighting_output_channels` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table rooms
# ------------------------------------------------------------

CREATE TABLE `rooms` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `floor_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `rooms_fk0` (`floor_id`),
  CONSTRAINT `rooms_fk0` FOREIGN KEY (`floor_id`) REFERENCES `floors` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;




/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;
/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
