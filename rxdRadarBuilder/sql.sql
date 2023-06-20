CREATE TABLE `radarbuilder` (
  `id` int(11) NOT NULL,
  `name` varchar(25) NOT NULL,
  `coords` varchar(255) NOT NULL,
  `vitesse` int(11) NOT NULL,
  `taillezone` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

ALTER TABLE `radarbuilder`
  ADD PRIMARY KEY (`id`);


ALTER TABLE `radarbuilder`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;
COMMIT;

INSERT INTO `items` (`name`, `label`, `weight`) VALUES
	('waze', 'Waze', 1);