# SI-PRIMA Dashboard

Dashboard monitoring progress tugas untuk BPS (Badan Pusat Statistik) menggunakan R Shiny.

## Fitur Utama

- **Multi-role Authentication**: Pimpinan, Manager, dan Pekerja
- **Task Management**: Pembuatan dan penugasan tugas
- **Progress Tracking**: Monitoring real-time progress tugas
- **Reporting**: Laporan harian, mingguan, dan bulanan
- **Analytics**: Analisis kinerja tim dan produktivitas

## Struktur Database

Database menggunakan MariaDB/MySQL dengan 3 tabel utama:
- `users`: Data pengguna dengan role-based access
- `tasks`: Data tugas yang ditugaskan
- `progress`: Data progress tugas

## Setup dan Installation

### Prerequisites

- R (>= 4.0.0)
- MariaDB/MySQL Server
- Required R packages (akan diinstall otomatis)

### Database Setup

1. Buat database `bps_progress`
2. Jalankan script `database_schema.sql` untuk membuat struktur tabel
3. Update konfigurasi database di `app.R` (host, user, password)

### Running the Application

```r
# Install required packages
install.packages(c("shiny", "shinydashboard", "DBI", "RMariaDB", "pool", "DT", "ggplot2", "dplyr", "lubridate"))

# Run the application
shiny::runApp()
