SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

CREATE DATABASE IF NOT EXISTS `shareapp` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE `shareapp`;

CREATE TABLE `pendingshares` (
  `sessKey` char(8) NOT NULL,
  `sender` int(11) NOT NULL,
  `receiver` int(11) NOT NULL,
  `fileName` varchar(1024) NOT NULL,
  `fileSize` int(11) NOT NULL,
  `status` int(11) NOT NULL DEFAULT 0,
  `requestDate` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `rubrica` (
  `user_A` int(11) NOT NULL,
  `user_B` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `users` (
  `ID` int(11) NOT NULL,
  `username` varchar(32) NOT NULL,
  `password` varchar(255) NOT NULL,
  `lastSeen` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `authKey` char(64) NOT NULL,
  `avatar` varchar(255) NOT NULL DEFAULT 'generic.png'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


ALTER TABLE `pendingshares`
  ADD UNIQUE KEY `sessKey` (`sessKey`),
  ADD KEY `sender` (`sender`,`receiver`),
  ADD KEY `receiver` (`receiver`);

ALTER TABLE `rubrica`
  ADD UNIQUE KEY `PK` (`user_A`,`user_B`),
  ADD KEY `user_A` (`user_A`),
  ADD KEY `user_B` (`user_B`);

ALTER TABLE `users`
  ADD PRIMARY KEY (`ID`),
  ADD UNIQUE KEY `username` (`username`);


ALTER TABLE `users`
  MODIFY `ID` int(11) NOT NULL AUTO_INCREMENT;


ALTER TABLE `pendingshares`
  ADD CONSTRAINT `pendingshares_ibfk_1` FOREIGN KEY (`sender`) REFERENCES `users` (`ID`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `pendingshares_ibfk_2` FOREIGN KEY (`receiver`) REFERENCES `users` (`ID`) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE `rubrica`
  ADD CONSTRAINT `rubrica_ibfk_1` FOREIGN KEY (`user_A`) REFERENCES `users` (`ID`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `rubrica_ibfk_2` FOREIGN KEY (`user_B`) REFERENCES `users` (`ID`) ON DELETE CASCADE ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
