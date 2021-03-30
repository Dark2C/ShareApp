SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";
CREATE DATABASE IF NOT EXISTS `shareApp` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE `shareApp`;

DROP TABLE IF EXISTS `pendingShares`;
CREATE TABLE `pendingShares` (
  `sessKey` char(8) NOT NULL,
  `sender` int(11) NOT NULL,
  `receiver` int(11) NOT NULL,
  `fileName` varchar(1024) NOT NULL,
  `fileSize` int(11) NOT NULL,
  `status` int(11) NOT NULL DEFAULT 0,
  `requestDate` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DROP TABLE IF EXISTS `rubrica`;
CREATE TABLE `rubrica` (
  `user_A` int(11) NOT NULL,
  `user_B` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DROP TABLE IF EXISTS `rubricaSync`;
CREATE TABLE `rubricaSync` (
  `user_ID` int(11) NOT NULL,
  `phoneNumber` varchar(32) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DROP TABLE IF EXISTS `users`;
CREATE TABLE `users` (
  `ID` int(11) NOT NULL,
  `username` varchar(32) NOT NULL,
  `password` varchar(255) NOT NULL,
  `lastSeen` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `authKey` char(64) NOT NULL,
  `avatar` varchar(255) NOT NULL DEFAULT 'generic.png',
  `phoneNumber` varchar(32) DEFAULT NULL,
  `firebaseToken` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


ALTER TABLE `pendingShares`
  ADD UNIQUE KEY `sessKey` (`sessKey`),
  ADD KEY `sender` (`sender`,`receiver`),
  ADD KEY `receiver` (`receiver`);

ALTER TABLE `rubrica`
  ADD UNIQUE KEY `PK` (`user_A`,`user_B`),
  ADD KEY `user_A` (`user_A`),
  ADD KEY `user_B` (`user_B`);

ALTER TABLE `rubricaSync`
  ADD PRIMARY KEY (`user_ID`,`phoneNumber`);

ALTER TABLE `users`
  ADD PRIMARY KEY (`ID`),
  ADD UNIQUE KEY `username` (`username`),
  ADD UNIQUE KEY `phoneNumber` (`phoneNumber`);


ALTER TABLE `users`
  MODIFY `ID` int(11) NOT NULL AUTO_INCREMENT;


ALTER TABLE `pendingShares`
  ADD CONSTRAINT `pendingshares_ibfk_1` FOREIGN KEY (`sender`) REFERENCES `users` (`ID`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `pendingshares_ibfk_2` FOREIGN KEY (`receiver`) REFERENCES `users` (`ID`) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE `rubrica`
  ADD CONSTRAINT `rubrica_ibfk_1` FOREIGN KEY (`user_A`) REFERENCES `users` (`ID`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `rubrica_ibfk_2` FOREIGN KEY (`user_B`) REFERENCES `users` (`ID`) ON DELETE CASCADE ON UPDATE CASCADE;
  
ALTER TABLE `rubricaSync`
  ADD CONSTRAINT `rubricasync_ibfk_1` FOREIGN KEY (`user_ID`) REFERENCES `users` (`ID`) ON DELETE CASCADE ON UPDATE CASCADE;
COMMIT;