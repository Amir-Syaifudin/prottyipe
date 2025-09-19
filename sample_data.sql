-- Added sample tasks and progress data to populate dropdowns
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
