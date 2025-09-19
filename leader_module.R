library(shiny)
library(DBI)
library(pool)
library(ggplot2)
library(dplyr)
library(lubridate)
library(DT)

leaderUI <- function(id){
  ns <- NS(id)
  fluidRow(
    # Kotak Filter
    box(title="Filter Rekapitulasi", width=12, solidHeader=TRUE, status="info",
        fluidRow(
          column(3, selectizeInput(ns("filter_manager"), "Filter by Manager", choices = NULL)),
          column(3, selectizeInput(ns("filter_worker"), "Filter by Worker", choices = NULL)),
          column(3, selectizeInput(ns("filter_task"), "Filter by Task", choices = NULL)),
          column(3,
                 selectizeInput(ns("filter_month"), "Filter by Month", choices = c("All", 1:12)),
                 selectizeInput(ns("filter_year"), "Filter by Year", choices = c("All", 2023:2030))
          )
        )
    ),
    # Grafik rekap
    box(title="Rekap Progress (Grafik)", width=12, solidHeader=TRUE, status="success",
        plotOutput(ns("leader_plot")),
        downloadButton(ns("export_excel"), "Export Excel")
    ),
    # Tabel detail
    box(title="Detail Progress (Tabel)", width=12, solidHeader=TRUE, status="primary",
        DTOutput(ns("leader_table"))
    )
  )
}

leaderServer <- function(input, output, session, pool){
  ns <- session$ns
  
  # Ambil data progres dari database
  progress_data_all <- reactive({
    tryCatch({
      result <- dbGetQuery(pool, "
        SELECT
          t.task_name, 
          u.username AS pekerja, 
          u2.username AS manager, 
          p.progress_percent, 
          p.updated_at
        FROM progress p
        JOIN tasks t ON p.task_id = t.id
        JOIN users u ON p.pekerja_id = u.id
        JOIN users u2 ON t.manager_id = u2.id
      ")
      
      if(nrow(result) == 0) {
        showNotification("Tidak ada data progress ditemukan", type = "warning")
        return(data.frame())
      }
      
      result %>% mutate(updated_at = as.Date(updated_at))
    }, error = function(e) {
      showNotification(paste("Error mengambil data:", e$message), type = "error")
      return(data.frame())
    })
  })
  
  # Update pilihan filter
  observe({
    df <- progress_data_all()
    if(nrow(df) > 0) {
      updateSelectizeInput(session, "filter_manager", 
                          choices = c("All", unique(df$manager)), 
                          selected = "All")
      updateSelectizeInput(session, "filter_worker", 
                          choices = c("All", unique(df$pekerja)), 
                          selected = "All")
      updateSelectizeInput(session, "filter_task", 
                          choices = c("All", unique(df$task_name)), 
                          selected = "All")
    } else {
      updateSelectizeInput(session, "filter_manager", choices = c("All"), selected = "All")
      updateSelectizeInput(session, "filter_worker", choices = c("All"), selected = "All")
      updateSelectizeInput(session, "filter_task", choices = c("All"), selected = "All")
    }
  })
  
  # Filter data
  filtered_data <- reactive({
    df <- progress_data_all()
    
    if(nrow(df) == 0) {
      return(df)
    }
    
    # Apply filters only if they exist and are not "All"
    if (!is.null(input$filter_manager) && input$filter_manager != "All") {
      df <- filter(df, manager == input$filter_manager)
    }
    if (!is.null(input$filter_worker) && input$filter_worker != "All") {
      df <- filter(df, pekerja == input$filter_worker)
    }
    if (!is.null(input$filter_task) && input$filter_task != "All") {
      df <- filter(df, task_name == input$filter_task)
    }
    if (!is.null(input$filter_month) && input$filter_month != "All") {
      df <- filter(df, month(updated_at) == as.integer(input$filter_month))
    }
    if (!is.null(input$filter_year) && input$filter_year != "All") {
      df <- filter(df, year(updated_at) == as.integer(input$filter_year))
    }
    
    df
  })
  
  # Plot rekap
  output$leader_plot <- renderPlot({
    df <- filtered_data()
    if(nrow(df) > 0){
      ggplot(df, aes(x=reorder(pekerja, -progress_percent), y=progress_percent, fill=pekerja)) +
        geom_bar(stat="identity") +
        geom_text(aes(label=paste0(progress_percent, "%")), vjust=-0.5, size=4) +
        labs(title="Rekap Progres Pekerja", x="Pekerja", y="Progress (%)") +
        theme_minimal() +
        theme(legend.position="none", 
              plot.title = element_text(hjust = 0.5, size = 16),
              axis.text.x = element_text(angle = 45, hjust = 1)) +
        ylim(0, max(df$progress_percent) * 1.1)
    } else {
      # Show empty plot with message
      ggplot() + 
        annotate("text", x = 0.5, y = 0.5, label = "Tidak ada data untuk ditampilkan", size = 6) +
        theme_void()
    }
  })
  
  # Tabel detail
  output$leader_table <- renderDT({
    df <- filtered_data()
    if(nrow(df) > 0) {
      datatable(df, rownames = FALSE,
                options = list(pageLength = 10, autoWidth = TRUE))
    } else {
      datatable(data.frame("Pesan" = "Tidak ada data untuk ditampilkan"), 
                rownames = FALSE, options = list(pageLength = 5))
    }
  })
  
  # Export Excel
  output$export_excel <- downloadHandler(
    filename = function() { paste0("rekap_progress_", Sys.Date(), ".csv") },
    content = function(file) {
      df <- filtered_data()
      write.csv(df, file, row.names = FALSE)
    }
  )
}

leaderPerformanceUI <- function(id) {
  ns <- NS(id)
  fluidRow(
    box(title = "Kinerja Tim", width = 12, solidHeader = TRUE, status = "warning",
        DTOutput(ns("performance_table")),
        plotOutput(ns("performance_chart"))
    )
  )
}

leaderPerformanceServer <- function(input, output, session, pool) {
  ns <- session$ns
  
  output$performance_table <- renderDT({
    tryCatch({
      performance_data <- dbGetQuery(pool, "
        SELECT 
          u.username AS pekerja,
          COUNT(t.id) AS total_tugas,
          AVG(COALESCE(p.progress_percent, 0)) AS avg_progress,
          COUNT(CASE WHEN p.progress_percent = 100 THEN 1 END) AS tugas_selesai
        FROM users u
        LEFT JOIN tasks t ON u.id = t.pekerja_id
        LEFT JOIN progress p ON t.id = p.task_id
        WHERE u.role = 'pekerja'
        GROUP BY u.id, u.username
      ")
      
      if(nrow(performance_data) > 0) {
        datatable(performance_data, rownames = FALSE,
                  options = list(pageLength = 10, autoWidth = TRUE))
      } else {
        datatable(data.frame("Pesan" = "Tidak ada data kinerja"), rownames = FALSE)
      }
    }, error = function(e) {
      datatable(data.frame("Pesan" = "Error loading performance data"), rownames = FALSE)
    })
  })
  
  output$performance_chart <- renderPlot({
    tryCatch({
      performance_data <- dbGetQuery(pool, "
        SELECT 
          u.username AS pekerja,
          AVG(COALESCE(p.progress_percent, 0)) AS avg_progress
        FROM users u
        LEFT JOIN tasks t ON u.id = t.pekerja_id
        LEFT JOIN progress p ON t.id = p.task_id
        WHERE u.role = 'pekerja'
        GROUP BY u.id, u.username
      ")
      
      if(nrow(performance_data) > 0) {
        ggplot(performance_data, aes(x = reorder(pekerja, -avg_progress), y = avg_progress, fill = pekerja)) +
          geom_bar(stat = "identity") +
          geom_text(aes(label = paste0(round(avg_progress, 1), "%")), vjust = -0.5) +
          labs(title = "Rata-rata Kinerja Tim", x = "Pekerja", y = "Rata-rata Progress (%)") +
          theme_minimal() +
          theme(legend.position = "none", axis.text.x = element_text(angle = 45, hjust = 1))
      } else {
        ggplot() + annotate("text", x = 0.5, y = 0.5, label = "Tidak ada data kinerja", size = 6) + theme_void()
      }
    }, error = function(e) {
      ggplot() + annotate("text", x = 0.5, y = 0.5, label = "Error loading chart", size = 6) + theme_void()
    })
  })
}

leaderProjectsUI <- function(id) {
  ns <- NS(id)
  fluidRow(
    box(title = "Status Proyek", width = 12, solidHeader = TRUE, status = "info",
        DTOutput(ns("projects_table")),
        plotOutput(ns("projects_chart"))
    )
  )
}

leaderProjectsServer <- function(input, output, session, pool) {
  ns <- session$ns
  
  output$projects_table <- renderDT({
    tryCatch({
      projects_data <- dbGetQuery(pool, "
        SELECT 
          t.task_name AS proyek,
          u.username AS manager,
          u2.username AS pekerja,
          COALESCE(MAX(p.progress_percent), 0) AS progress_percent,
          CASE 
            WHEN MAX(p.progress_percent) = 100 THEN 'Selesai'
            WHEN MAX(p.progress_percent) >= 50 THEN 'Dalam Progress'
            ELSE 'Baru Dimulai'
          END AS status
        FROM tasks t
        JOIN users u ON t.manager_id = u.id
        JOIN users u2 ON t.pekerja_id = u2.id
        LEFT JOIN progress p ON t.id = p.task_id
        GROUP BY t.id, t.task_name, u.username, u2.username
      ")
      datatable(projects_data, rownames = FALSE,
                options = list(pageLength = 10, autoWidth = TRUE))
    }, error = function(e) {
      datatable(data.frame(Message = "Error loading projects data"), rownames = FALSE)
    })
  })
  
  output$projects_chart <- renderPlot({
    tryCatch({
      status_data <- dbGetQuery(pool, "
        SELECT 
          CASE 
            WHEN MAX(p.progress_percent) = 100 THEN 'Selesai'
            WHEN MAX(p.progress_percent) >= 50 THEN 'Dalam Progress'
            ELSE 'Baru Dimulai'
          END AS status,
          COUNT(*) AS jumlah
        FROM tasks t
        LEFT JOIN progress p ON t.id = p.task_id
        GROUP BY 
          CASE 
            WHEN MAX(p.progress_percent) = 100 THEN 'Selesai'
            WHEN MAX(p.progress_percent) >= 50 THEN 'Dalam Progress'
            ELSE 'Baru Dimulai'
          END
      ")
      
      if(nrow(status_data) > 0) {
        ggplot(status_data, aes(x = status, y = jumlah, fill = status)) +
          geom_bar(stat = "identity") +
          geom_text(aes(label = jumlah), vjust = -0.5) +
          labs(title = "Status Proyek", x = "Status", y = "Jumlah Proyek") +
          theme_minimal() +
          theme(legend.position = "none")
      } else {
        ggplot() + annotate("text", x = 0.5, y = 0.5, label = "Tidak ada data proyek", size = 6) + theme_void()
      }
    }, error = function(e) {
      ggplot() + annotate("text", x = 0.5, y = 0.5, label = "Error loading chart", size = 6) + theme_void()
    })
  })
}

leaderDailyReportUI <- function(id) {
  ns <- NS(id)
  fluidRow(
    box(title = "Laporan Harian", width = 12, solidHeader = TRUE, status = "success",
        dateInput(ns("report_date"), "Pilih Tanggal", value = Sys.Date()),
        DTOutput(ns("daily_table")),
        downloadButton(ns("download_daily"), "Download Laporan Harian")
    )
  )
}

leaderDailyReportServer <- function(input, output, session, pool) {
  ns <- session$ns
  
  output$daily_table <- renderDT({
    tryCatch({
      daily_data <- dbGetQuery(pool, "
        SELECT 
          t.task_name AS tugas,
          u.username AS pekerja,
          p.progress_percent AS progress,
          p.updated_at AS tanggal_update
        FROM progress p
        JOIN tasks t ON p.task_id = t.id
        JOIN users u ON p.pekerja_id = u.id
        WHERE DATE(p.updated_at) = ?
        ORDER BY p.updated_at DESC
      ", params = list(input$report_date))
      
      datatable(daily_data, rownames = FALSE,
                options = list(pageLength = 10, autoWidth = TRUE))
    }, error = function(e) {
      datatable(data.frame(Message = "Error loading daily report"), rownames = FALSE)
    })
  })
  
  output$download_daily <- downloadHandler(
    filename = function() { paste0("laporan_harian_", input$report_date, ".csv") },
    content = function(file) {
      daily_data <- dbGetQuery(pool, "
        SELECT 
          t.task_name AS tugas,
          u.username AS pekerja,
          p.progress_percent AS progress,
          p.updated_at AS tanggal_update
        FROM progress p
        JOIN tasks t ON p.task_id = t.id
        JOIN users u ON p.pekerja_id = u.id
        WHERE DATE(p.updated_at) = ?
        ORDER BY p.updated_at DESC
      ", params = list(input$report_date))
      write.csv(daily_data, file, row.names = FALSE)
    }
  )
}

leaderWeeklyReportUI <- function(id) {
  ns <- NS(id)
  fluidRow(
    box(title = "Laporan Mingguan", width = 12, solidHeader = TRUE, status = "warning",
        dateRangeInput(ns("week_range"), "Pilih Rentang Minggu", 
                      start = Sys.Date() - 7, end = Sys.Date()),
        DTOutput(ns("weekly_table")),
        downloadButton(ns("download_weekly"), "Download Laporan Mingguan")
    )
  )
}

leaderWeeklyReportServer <- function(input, output, session, pool) {
  ns <- session$ns
  
  output$weekly_table <- renderDT({
    tryCatch({
      weekly_data <- dbGetQuery(pool, "
        SELECT 
          u.username AS pekerja,
          COUNT(DISTINCT t.id) AS total_tugas,
          AVG(p.progress_percent) AS avg_progress,
          COUNT(CASE WHEN p.progress_percent = 100 THEN 1 END) AS tugas_selesai
        FROM progress p
        JOIN tasks t ON p.task_id = t.id
        JOIN users u ON p.pekerja_id = u.id
        WHERE DATE(p.updated_at) BETWEEN ? AND ?
        GROUP BY u.id, u.username
      ", params = list(input$week_range[1], input$week_range[2]))
      
      datatable(weekly_data, rownames = FALSE,
                options = list(pageLength = 10, autoWidth = TRUE))
    }, error = function(e) {
      datatable(data.frame(Message = "Error loading weekly report"), rownames = FALSE)
    })
  })
  
  output$download_weekly <- downloadHandler(
    filename = function() { paste0("laporan_mingguan_", Sys.Date(), ".csv") },
    content = function(file) {
      weekly_data <- dbGetQuery(pool, "
        SELECT 
          u.username AS pekerja,
          COUNT(DISTINCT t.id) AS total_tugas,
          AVG(p.progress_percent) AS avg_progress,
          COUNT(CASE WHEN p.progress_percent = 100 THEN 1 END) AS tugas_selesai
        FROM progress p
        JOIN tasks t ON p.task_id = t.id
        JOIN users u ON p.pekerja_id = u.id
        WHERE DATE(p.updated_at) BETWEEN ? AND ?
        GROUP BY u.id, u.username
      ", params = list(input$week_range[1], input$week_range[2]))
      write.csv(weekly_data, file, row.names = FALSE)
    }
  )
}

leaderMonthlyReportUI <- function(id) {
  ns <- NS(id)
  fluidRow(
    box(title = "Laporan Bulanan", width = 12, solidHeader = TRUE, status = "primary",
        selectInput(ns("report_month"), "Pilih Bulan", 
                   choices = setNames(1:12, month.name), selected = month(Sys.Date())),
        selectInput(ns("report_year"), "Pilih Tahun", 
                   choices = 2023:2030, selected = year(Sys.Date())),
        DTOutput(ns("monthly_table")),
        plotOutput(ns("monthly_chart")),
        downloadButton(ns("download_monthly"), "Download Laporan Bulanan")
    )
  )
}

leaderMonthlyReportServer <- function(input, output, session, pool) {
  ns <- session$ns
  
  monthly_data <- reactive({
    tryCatch({
      dbGetQuery(pool, "
        SELECT 
          u.username AS pekerja,
          COUNT(DISTINCT t.id) AS total_tugas,
          AVG(p.progress_percent) AS avg_progress,
          COUNT(CASE WHEN p.progress_percent = 100 THEN 1 END) AS tugas_selesai,
          (COUNT(CASE WHEN p.progress_percent = 100 THEN 1 END) / COUNT(DISTINCT t.id)) * 100 AS completion_rate
        FROM progress p
        JOIN tasks t ON p.task_id = t.id
        JOIN users u ON p.pekerja_id = u.id
        WHERE MONTH(p.updated_at) = ? AND YEAR(p.updated_at) = ?
        GROUP BY u.id, u.username
      ", params = list(input$report_month, input$report_year))
    }, error = function(e) {
      data.frame(Message = "Error loading monthly data")
    })
  })
  
  output$monthly_table <- renderDT({
    datatable(monthly_data(), rownames = FALSE,
              options = list(pageLength = 10, autoWidth = TRUE))
  })
  
  output$monthly_chart <- renderPlot({
    data <- monthly_data()
    if(nrow(data) > 0 && "completion_rate" %in% names(data)) {
      ggplot(data, aes(x = reorder(pekerja, -completion_rate), y = completion_rate, fill = pekerja)) +
        geom_bar(stat = "identity") +
        geom_text(aes(label = paste0(round(completion_rate, 1), "%")), vjust = -0.5) +
        labs(title = "Tingkat Penyelesaian Bulanan", x = "Pekerja", y = "Completion Rate (%)") +
        theme_minimal() +
        theme(legend.position = "none", axis.text.x = element_text(angle = 45, hjust = 1))
    } else {
      ggplot() + annotate("text", x = 0.5, y = 0.5, label = "Tidak ada data bulanan", size = 6) + theme_void()
    }
  })
  
  output$download_monthly <- downloadHandler(
    filename = function() { paste0("laporan_bulanan_", input$report_month, "_", input$report_year, ".csv") },
    content = function(file) {
      write.csv(monthly_data(), file, row.names = FALSE)
    }
  )
}
