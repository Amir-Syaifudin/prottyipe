-- Script untuk mengisi database dengan data sample
USE bps_progress;

-- Hapus data lama jika ada
DELETE FROM progress;
DELETE FROM tasks;
DELETE FROM users;

-- Insert users sample
INSERT INTO users (username, password, role) VALUES
('admin', 'admin123', 'pimpinan'),
('manager1', 'manager123', 'manager'),
('manager2', 'manager123', 'manager'),
('pekerja1', 'pekerja123', 'pekerja'),
('pekerja2', 'pekerja123', 'pekerja'),
('pekerja3', 'pekerja123', 'pekerja'),
('pekerja4', 'pekerja123', 'pekerja');

-- Insert tasks sample
INSERT INTO tasks (task_name, manager_id, pekerja_id) VALUES
('Analisis Data Penduduk', 2, 4),
('Survey Ekonomi Rumah Tangga', 2, 5),
('Laporan Statistik Bulanan', 3, 6),
('Pengolahan Data Sensus', 3, 7),
('Validasi Data Regional', 2, 4),
('Kompilasi Data Nasional', 3, 5);

-- Insert progress sample
INSERT INTO progress (task_id, progress_percent, pekerja_id, updated_at) VALUES
(1, 75, 4, '2024-01-15 10:30:00'),
(1, 85, 4, '2024-01-16 14:20:00'),
(2, 60, 5, '2024-01-15 09:15:00'),
(2, 70, 5, '2024-01-16 16:45:00'),
(3, 90, 6, '2024-01-14 11:00:00'),
(3, 95, 6, '2024-01-16 13:30:00'),
(4, 45, 7, '2024-01-15 15:20:00'),
(5, 30, 4, '2024-01-16 08:45:00'),
(6, 80, 5, '2024-01-15 17:10:00');
