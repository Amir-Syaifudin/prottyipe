library(DBI)
library(RMariaDB)
library(pool)

# Pooling agar koneksi efisien
pool <- dbPool(
  drv = RMariaDB::MariaDB(),
  dbname = "bps_progress",
  host = "127.0.0.1",
  user = "bps_user",
  password = "",   # ganti sesuai password mysql kamu
  port = 3306
)

# === TEST KONEKSI (sementara, sebelum runApp) ===
con <- poolCheckout(pool)
print(dbListTables(con))  # cek apakah keluar tabel-tabel
poolReturn(con)
# ================================================

# Fungsi ambil data
get_progress <- function(){
  dbReadTable(pool, "progress")
}

# Tutup koneksi saat app ditutup
onStop(function() {
  poolClose(pool)
})

# lanjut UI + server Shiny kamu di bawah sini
