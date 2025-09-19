library(shiny)
library(DT)
library(DBI)
library(pool)

workerUI <- function(id){
  ns <- NS(id)
  fluidRow(
    box(title="Isi Progress", width=6, solidHeader=TRUE, status="primary",
        selectizeInput(ns("task_to_update"), "Pilih Tugas", choices = NULL),
        numericInput(ns("progress_percent"), "Progress (%)", 0, min=0, max=100),
        actionButton(ns("submit"), "Kirim", class="btn-custom")
    ),
    box(title="Riwayat Progress", width=6, solidHeader=TRUE, status="primary",
        DTOutput(ns("table_history"))
    )
  )
}

workerServer <- function(input, output, session, user, pool){
  ns <- session$ns
  
  # Sinyal untuk refresh tabel
  refresh_signal <- reactiveVal(0)
  
  assigned_tasks <- reactive({
    req(user, pool)
    tryCatch({
      df <- dbGetQuery(pool, "SELECT id, task_name FROM tasks WHERE pekerja_id = ?", 
                       params = list(user$id))
      if(nrow(df) > 0) {
        setNames(df$id, df$task_name)
      } else {
        c("Tidak ada tugas" = "")
      }
    }, error = function(e) {
      showNotification(paste("Error loading tasks:", e$message), type = "error")
      c("Error loading tasks" = "")
    })
  })
  
  # Perbarui pilihan tugas
  observe({
    choices <- assigned_tasks()
    updateSelectizeInput(session, "task_to_update", choices = choices)
  })
  
  # Submit progress
  observeEvent(input$submit, {
    req(input$task_to_update, input$progress_percent, user)
    
    if(input$task_to_update == "") {
      showNotification("Pilih tugas terlebih dahulu", type = "warning")
      return()
    }
    
    task_id <- as.integer(input$task_to_update)
    progress_val <- input$progress_percent
    
    tryCatch({
      dbExecute(pool, "INSERT INTO progress (task_id, progress_percent, pekerja_id, updated_at) 
                       VALUES (?, ?, ?, NOW())",
                params = list(task_id, progress_val, user$id))
      
      showNotification("Progress berhasil disimpan", type="message")
      refresh_signal(refresh_signal() + 1)
    }, error = function(e) {
      showNotification(paste("Error saving progress:", e$message), type = "error")
    })
  })
  
  progress_history_data <- eventReactive(refresh_signal(), {
    req(user, pool)
    tryCatch({
      dbGetQuery(pool, "SELECT t.task_name, p.progress_percent, p.updated_at
                        FROM progress p
                        JOIN tasks t ON p.task_id = t.id
                        WHERE p.pekerja_id = ?
                        ORDER BY p.updated_at DESC", 
                 params = list(user$id))
    }, error = function(e) {
      showNotification(paste("Error loading history:", e$message), type = "error")
      data.frame(task_name = character(0), progress_percent = numeric(0), updated_at = character(0))
    })
  }, ignoreNULL = FALSE)
  
  # Render tabel history
  output$table_history <- renderDT({
    data <- progress_history_data()
    if(nrow(data) > 0) {
      datatable(data, rownames = FALSE,
                options = list(pageLength = 5, autoWidth = TRUE))
    } else {
      datatable(data.frame("Pesan" = "Belum ada riwayat progress"), 
                rownames = FALSE, options = list(pageLength = 5))
    }
  })
}
