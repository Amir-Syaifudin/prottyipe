library(shiny)
library(DT)
library(DBI)
library(pool)

managerUI <- function(id){
  ns <- NS(id)
  
  fluidRow(
    # Kotak untuk membuat tugas baru
    box(
      title = "Buat Tugas Baru",
      width = 6,
      solidHeader = TRUE,
      status = "primary",
      textInput(ns("new_task_name"), "Nama Tugas"),
      selectizeInput(ns("assign_worker"), "Tugaskan ke Pekerja", choices = NULL),
      actionButton(ns("create_task_btn"), "Buat Tugas", class = "btn-custom")
    ),
    
    # Kotak untuk monitoring tugas
    box(
      title = "Monitoring Tugas & Progres",
      width = 6,
      solidHeader = TRUE,
      status = "warning",
      DTOutput(ns("manager_progress_table"))
    )
  )
}

managerServer <- function(input, output, session, user, pool){
  ns <- session$ns
  
  # Sinyal untuk memicu refresh tabel
  refresh_signal <- reactiveVal(0)
  
  pekerja_list <- reactive({
    req(pool)
    tryCatch({
      df <- dbGetQuery(pool, "SELECT id, username FROM users WHERE role = 'pekerja'")
      if(nrow(df) > 0) {
        setNames(df$id, df$username)
      } else {
        c("Tidak ada pekerja" = "")
      }
    }, error = function(e) {
      showNotification(paste("Error loading workers:", e$message), type = "error")
      c("Error loading workers" = "")
    })
  })
  
  # Perbarui pilihan di selectizeInput saat daftar pekerja berubah
  observe({
    choices <- pekerja_list()
    updateSelectizeInput(session, "assign_worker", choices = choices)
  })
  
  # Logika untuk membuat tugas baru
  observeEvent(input$create_task_btn, {
    req(input$new_task_name, input$assign_worker, user)
    
    task_name <- trimws(input$new_task_name)
    if (task_name == "") {
      showNotification("Nama tugas tidak boleh kosong!", type = "error")
      return()
    }
    
    if(input$assign_worker == "") {
      showNotification("Pilih pekerja terlebih dahulu!", type = "error")
      return()
    }
    
    pekerja_id <- as.integer(input$assign_worker)
    manager_id <- user$id
    
    tryCatch({
      dbExecute(pool, 
                "INSERT INTO tasks (task_name, manager_id, pekerja_id) VALUES (?, ?, ?)",
                params = list(task_name, manager_id, pekerja_id))
      
      showNotification("Tugas berhasil dibuat!", type = "message")
      updateTextInput(session, "new_task_name", value = "")
      refresh_signal(refresh_signal() + 1)
    }, error = function(e) {
      showNotification(paste("Error creating task:", e$message), type = "error")
    })
  })
  
  progress_data <- eventReactive(refresh_signal(), {
    req(user, pool)
    tryCatch({
      dbGetQuery(pool, "
        SELECT 
          t.task_name, 
          u.username AS pekerja, 
          COALESCE(MAX(p.progress_percent), 0) AS progress_percent, 
          COALESCE(MAX(p.updated_at), 'Belum ada update') AS updated_at
        FROM tasks t
        JOIN users u ON t.pekerja_id = u.id
        LEFT JOIN progress p ON t.id = p.task_id
        WHERE t.manager_id = ?
        GROUP BY t.id, t.task_name, u.username
        ORDER BY t.id DESC",
                 params = list(user$id))
    }, error = function(e) {
      showNotification(paste("Error loading progress data:", e$message), type = "error")
      data.frame(task_name = character(0), pekerja = character(0), 
                 progress_percent = numeric(0), updated_at = character(0))
    })
  }, ignoreNULL = FALSE)
  
  output$manager_progress_table <- renderDT({
    data <- progress_data()
    if(nrow(data) > 0) {
      datatable(data, 
                options = list(pageLength = 5, autoWidth = TRUE),
                rownames = FALSE,
                editable = FALSE)
    } else {
      datatable(data.frame("Pesan" = "Belum ada tugas yang dibuat"), 
                rownames = FALSE, options = list(pageLength = 5))
    }
  })
}
