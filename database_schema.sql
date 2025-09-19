-- Updated to match user's exact database structure from bps_progress.sql
-- phpMyAdmin SQL Dump structure matching user's database
SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

-- Database: `bps_progress`
CREATE DATABASE IF NOT EXISTS `bps_progress`;
USE `bps_progress`;

-- Table structure for table `progress`
CREATE TABLE `progress` (
  `id` int(11) NOT NULL,
  `task_id` int(11) NOT NULL,
  `worker_id` int(11) DEFAULT NULL,
  `pekerja_id` int(11) NOT NULL,
  `progress_percent` int(11) NOT NULL DEFAULT 0,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Table structure for table `tasks`
CREATE TABLE `tasks` (
  `id` int(11) NOT NULL,
  `task_name` varchar(100) NOT NULL,
  `manager_id` int(11) NOT NULL,
  `pekerja_id` int(11) NOT NULL,
  `deadline` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Table structure for table `users`
CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `username` varchar(50) NOT NULL,
  `password` varchar(255) NOT NULL,
  `role` enum('pekerja','manager','pimpinan') NOT NULL,
  `manager_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for table `users`
INSERT INTO `users` (`id`, `username`, `password`, `role`, `manager_id`) VALUES
(1, 'pimpinan', '1234', 'pimpinan', NULL),
(2, 'manager1', '1234', 'manager', NULL),
(3, 'manager2', '1234', 'manager', NULL),
(4, 'pekerja1', '1234', 'pekerja', 2),
(5, 'pekerja2', '1234', 'pekerja', 2),
(6, 'pekerja3', '1234', 'pekerja', 3),
(7, 'pimpinan1', '1234', 'pimpinan', NULL);

-- Sample tasks data
INSERT INTO `tasks` (`id`, `task_name`, `manager_id`, `pekerja_id`, `deadline`) VALUES
(1, 'Analisis Data Penduduk', 2, 4, '2025-10-15'),
(2, 'Survey Ekonomi Rumah Tangga', 2, 5, '2025-10-20'),
(3, 'Pengolahan Data Sensus', 3, 6, '2025-11-01'),
(4, 'Laporan Statistik Bulanan', 2, 4, '2025-09-30'),
(5, 'Verifikasi Data Lapangan', 3, 6, '2025-10-10'),
(6, 'Input Data Kuesioner', 2, 5, '2025-09-25'),
(7, 'Cleaning Data Survey', 3, 6, '2025-10-05'),
(8, 'Analisis Tren Ekonomi', 2, 4, '2025-11-15'),
(9, 'Penyusunan Grafik Statistik', 2, 5, '2025-10-12'),
(10, 'Review Data Quality', 3, 6, '2025-09-28');

-- Sample progress data
INSERT INTO `progress` (`id`, `task_id`, `worker_id`, `pekerja_id`, `progress_percent`, `updated_at`) VALUES
(1, 1, NULL, 4, 75, '2025-09-18 10:30:00'),
(2, 2, NULL, 5, 45, '2025-09-18 11:15:00'),
(3, 3, NULL, 6, 60, '2025-09-18 09:45:00'),
(4, 4, NULL, 4, 90, '2025-09-18 14:20:00'),
(5, 5, NULL, 6, 30, '2025-09-18 08:30:00'),
(6, 6, NULL, 5, 85, '2025-09-18 13:10:00'),
(7, 7, NULL, 6, 55, '2025-09-18 12:00:00'),
(8, 8, NULL, 4, 25, '2025-09-18 15:45:00'),
(9, 9, NULL, 5, 70, '2025-09-18 16:30:00'),
(10, 10, NULL, 6, 40, '2025-09-18 07:15:00');

-- Indexes for table `progress`
ALTER TABLE `progress`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_task_worker` (`task_id`,`pekerja_id`),
  ADD KEY `pekerja_id` (`pekerja_id`);

-- Indexes for table `tasks`
ALTER TABLE `tasks`
  ADD PRIMARY KEY (`id`),
  ADD KEY `manager_id` (`manager_id`),
  ADD KEY `pekerja_id` (`pekerja_id`);

-- Indexes for table `users`
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username` (`username`),
  ADD KEY `manager_id` (`manager_id`);

-- AUTO_INCREMENT for table `progress`
ALTER TABLE `progress`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=19;

-- AUTO_INCREMENT for table `tasks`
ALTER TABLE `tasks`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

-- AUTO_INCREMENT for table `users`
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

-- Constraints for table `progress`
ALTER TABLE `progress`
  ADD CONSTRAINT `progress_ibfk_1` FOREIGN KEY (`task_id`) REFERENCES `tasks` (`id`),
  ADD CONSTRAINT `progress_ibfk_2` FOREIGN KEY (`pekerja_id`) REFERENCES `users` (`id`);

-- Constraints for table `tasks`
ALTER TABLE `tasks`
  ADD CONSTRAINT `tasks_ibfk_1` FOREIGN KEY (`manager_id`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `tasks_ibfk_2` FOREIGN KEY (`pekerja_id`) REFERENCES `users` (`id`);

-- Constraints for table `users`
ALTER TABLE `users`
  ADD CONSTRAINT `users_ibfk_1` FOREIGN KEY (`manager_id`) REFERENCES `users` (`id`);

COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
