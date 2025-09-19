library(shiny)
library(shinydashboard)
library(DBI)
library(RMariaDB)
library(pool)
library(DT)
library(ggplot2)
library(dplyr)
library(lubridate)

# Load global configuration
source("global.R")

# Source modules
source("modules/leader_module.R")
source("modules/worker_module.R")
source("modules/manager_module.R")

# Create database connection pool
pool <- create_db_pool()

# UI
ui <- dashboardPage(
  dashboardHeader(
    title = "SI-PRIMA",
    tags$li(
      class = "dropdown",
      conditionalPanel(
        condition = "output.user_logged_in",
        actionButton("logout_btn", "Logout", icon = icon("sign-out-alt"), 
                     style = "background-color: #d9534f; color: white;")
      )
    )
  ),
  dashboardSidebar(
    conditionalPanel(
      condition = "output.user_logged_in",
      sidebarMenuOutput("sidebar")
    )
  ),
  dashboardBody(
    tags$head(
      tags$link(rel = "stylesheet", type = "text/css", href = "custom.css")
    ),
    conditionalPanel(
      condition = "!output.user_logged_in",
      fluidRow(
        column(6, offset = 3,
          box(
            title = "Login SI-PRIMA", 
            width = 12, 
            status = "primary", 
            solidHeader = TRUE,
            textInput("username", "Username"),
            passwordInput("password", "Password"),
            actionButton("login_btn", "Login", class = "btn-primary"),
            br(), br(),
            # Kotak informasi akun prototipe
            box(
              title = "Info Akun Prototipe",
              width = 12,
              status = "info",
              solidHeader = TRUE,
              p(strong("Pimpinan:"), " username: pimpinan, password: 1234"),
              p(strong("Manager:"), " username: manager1 / manager2, password: 1234"),
              p(strong("Pekerja:"), " username: pekerja1 /pekerja2 / pekerja3, password: 1234")
            )
          )
        )
      )
    ),
    conditionalPanel(
      condition = "output.user_logged_in",
      tabItems(
        # Worker tabs
        tabItem(tabName = "worker_tasks",
          uiOutput("worker_tasks_ui")
        ),
        
        # Manager tabs  
        tabItem(tabName = "manager_create",
          uiOutput("manager_create_ui")
        ),
        tabItem(tabName = "manager_monitor",
          uiOutput("manager_monitor_ui")
        ),
        
        # Leader tabs
        tabItem(tabName = "leader_dashboard",
          uiOutput("leader_dashboard_ui")
        ),
        tabItem(tabName = "leader_progress",
          uiOutput("leader_progress_ui")
        ),
        tabItem(tabName = "leader_performance",
          uiOutput("leader_performance_ui")
        ),
        tabItem(tabName = "leader_projects",
          uiOutput("leader_projects_ui")
        ),
        tabItem(tabName = "leader_daily_report",
          uiOutput("leader_daily_report_ui")
        ),
        tabItem(tabName = "leader_weekly_report",
          uiOutput("leader_weekly_report_ui")
        ),
        tabItem(tabName = "leader_monthly_report",
          uiOutput("leader_monthly_report_ui")
        ),
        tabItem(tabName = "leader_productivity",
          uiOutput("leader_productivity_ui")
        ),
        tabItem(tabName = "leader_workload",
          uiOutput("leader_workload_ui")
        ),
        tabItem(tabName = "leader_trends",
          uiOutput("leader_trends_ui")
        ),
        tabItem(tabName = "leader_settings",
          uiOutput("leader_settings_ui")
        )
      )
    )
  )
)

# SERVER
server <- function(input, output, session) {
  
  # state login
  user_data <- reactiveVal(NULL)
  
  output$user_logged_in <- reactive({
    !is.null(user_data())
  })
  outputOptions(output, "user_logged_in", suspendWhenHidden = FALSE)

  # render sidebar sesuai role
  output$sidebar <- renderMenu({
    u <- user_data()
    if (is.null(u)) return(NULL)
    
    if (u$role == "pekerja") {
      sidebarMenu(
        menuItem("Tugas Saya", tabName = "worker_tasks", icon = icon("tasks"))
      )
    } else if (u$role == "manager") {
      sidebarMenu(
        menuItem("Buat Tugas", tabName = "manager_create", icon = icon("plus")),
        menuItem("Monitoring", tabName = "manager_monitor", icon = icon("eye"))
      )
    } else if (u$role == "pimpinan") {
      sidebarMenu(
        menuItem("Dashboard Utama", tabName = "leader_dashboard", icon = icon("tachometer-alt")),
        menuItem("Monitoring", icon = icon("chart-line"), startExpanded = FALSE,
          menuSubItem("Progress Keseluruhan", tabName = "leader_progress"),
          menuSubItem("Kinerja Tim", tabName = "leader_performance"),
          menuSubItem("Status Proyek", tabName = "leader_projects")
        ),
        menuItem("Laporan", icon = icon("file-alt"), startExpanded = FALSE,
          menuSubItem("Laporan Harian", tabName = "leader_daily_report"),
          menuSubItem("Laporan Mingguan", tabName = "leader_weekly_report"),
          menuSubItem("Laporan Bulanan", tabName = "leader_monthly_report")
        ),
        menuItem("Analisis", icon = icon("chart-bar"), startExpanded = FALSE,
          menuSubItem("Analisis Produktivitas", tabName = "leader_productivity"),
          menuSubItem("Analisis Beban Kerja", tabName = "leader_workload"),
          menuSubItem("Trend Analysis", tabName = "leader_trends")
        ),
        menuItem("Pengaturan", tabName = "leader_settings", icon = icon("cogs"))
      )
    }
  })
  
  # render body sesuai role
  output$worker_tasks_ui <- renderUI({
    u <- user_data()
    if (is.null(u) || u$role != "pekerja") return(NULL)
    
    source("modules/worker_module.R", local = TRUE)
    workerUI("worker")
  })
  
  output$manager_create_ui <- renderUI({
    u <- user_data()
    if (is.null(u) || u$role != "manager") return(NULL)
    
    source("modules/manager_module.R", local = TRUE)
    managerUI("manager")
  })
  
  output$manager_monitor_ui <- renderUI({
    u <- user_data()
    if (is.null(u) || u$role != "manager") return(NULL)
    
    fluidRow(
      box(title = "Monitoring Tugas & Progress", width = 12, solidHeader = TRUE, status = "warning",
          DTOutput("manager_monitor_table")
      )
    )
  })
  
  output$leader_dashboard_ui <- renderUI({
    u <- user_data()
    if (is.null(u) || u$role != "pimpinan") return(NULL)
    
    fluidRow(
      box(title = "Dashboard Utama", width = 12, solidHeader = TRUE, status = "primary",
          h3("Selamat datang di Dashboard Pimpinan"),
          p("Gunakan menu sidebar untuk mengakses berbagai fitur monitoring dan analisis.")
      )
    )
  })
  
  output$leader_progress_ui <- renderUI({
    u <- user_data()
    if (is.null(u) || u$role != "pimpinan") return(NULL)
    
    source("modules/leader_module.R", local = TRUE)
    leaderUI("leader")
  })
  
  output$leader_performance_ui <- renderUI({
    u <- user_data()
    if (u$role == "pimpinan") {
      source("modules/leader_module.R", local = TRUE)
      leaderPerformanceUI("leader_perf")
    }
  })
  
  output$leader_projects_ui <- renderUI({
    u <- user_data()
    if (u$role == "pimpinan") {
      source("modules/leader_module.R", local = TRUE)
      leaderProjectsUI("leader_proj")
    }
  })
  
  output$leader_daily_report_ui <- renderUI({
    u <- user_data()
    if (u$role == "pimpinan") {
      source("modules/leader_module.R", local = TRUE)
      leaderDailyReportUI("leader_daily")
    }
  })
  
  output$leader_weekly_report_ui <- renderUI({
    u <- user_data()
    if (u$role == "pimpinan") {
      source("modules/leader_module.R", local = TRUE)
      leaderWeeklyReportUI("leader_weekly")
    }
  })
  
  output$leader_monthly_report_ui <- renderUI({
    u <- user_data()
    if (u$role == "pimpinan") {
      source("modules/leader_module.R", local = TRUE)
      leaderMonthlyReportUI("leader_monthly")
    }
  })
  
  output$leader_productivity_ui <- renderUI({
    u <- user_data()
    if (u$role == "pimpinan") {
      fluidRow(
        box(title = "Analisis Produktivitas", width = 12, solidHeader = TRUE, status = "info",
            p("Analisis produktivitas akan ditampilkan di sini.")
        )
      )
    }
  })
  
  output$leader_workload_ui <- renderUI({
    u <- user_data()
    if (u$role == "pimpinan") {
      fluidRow(
        box(title = "Analisis Beban Kerja", width = 12, solidHeader = TRUE, status = "info",
            p("Analisis beban kerja akan ditampilkan di sini.")
        )
      )
    }
  })
  
  output$leader_trends_ui <- renderUI({
    u <- user_data()
    if (u$role == "pimpinan") {
      fluidRow(
        box(title = "Trend Analysis", width = 12, solidHeader = TRUE, status = "info",
            p("Analisis trend akan ditampilkan di sini.")
        )
      )
    }
  })
  
  output$leader_settings_ui <- renderUI({
    u <- user_data()
    if (u$role == "pimpinan") {
      fluidRow(
        box(title = "Pengaturan", width = 12, solidHeader = TRUE, status = "primary",
            p("Pengaturan sistem akan ditampilkan di sini.")
        )
      )
    }
  })
  
  # otentikasi
  observeEvent(input$login_btn, {
    user <- dbGetQuery(pool, "SELECT * FROM users WHERE username = ? AND password = ?",
                       params = list(input$username, input$password))
    if (nrow(user) == 1) {
      user_data(user)
      showNotification(paste0("Selamat datang, ", user$username, " (", user$role, ")"), type = "message")
    } else {
      showNotification("Username atau password salah", type = "error")
    }
  })
  
  # Logout
  observeEvent(input$logout_btn, {
    user_data(NULL)
    showNotification("Anda telah logout", type = "message")
  })
  
  # server logic untuk manager & leader & worker
  observe({
    u <- user_data()
    if (is.null(u)) return(NULL)
    
    if (u$role == "pekerja") {
      moduleServer("worker", function(input, output, session) {
        workerServer(input, output, session, user = u, pool = pool)
      })
    } else if (u$role == "manager") {
      moduleServer("manager", function(input, output, session) {
        managerServer(input, output, session, user = u, pool = pool)
      })
      
      output$manager_monitor_table <- renderDT({
        progress_data <- dbGetQuery(pool, "
          SELECT 
            t.task_name, 
            u.username AS pekerja, 
            COALESCE(MAX(p.progress_percent), 0) AS progress_percent, 
            COALESCE(MAX(p.updated_at), 'Belum ada update') AS last_updated
          FROM tasks t
          JOIN users u ON t.pekerja_id = u.id
          LEFT JOIN progress p ON t.id = p.task_id
          WHERE t.manager_id = ?
          GROUP BY t.id, t.task_name, u.username
          ORDER BY t.id DESC",
          params = list(u$id)
        )
        
        if(nrow(progress_data) > 0) {
          datatable(progress_data, 
                    options = list(pageLength = 10, autoWidth = TRUE),
                    rownames = FALSE)
        } else {
          datatable(data.frame("Pesan" = "Belum ada tugas yang dibuat"), 
                    rownames = FALSE, options = list(pageLength = 5))
        }
      })
      
    } else if (u$role == "pimpinan") {
      moduleServer("leader", function(input, output, session) {
        leaderServer(input, output, session, pool = pool)
      })
      
      moduleServer("leader_perf", function(input, output, session) {
        leaderPerformanceServer(input, output, session, pool = pool)
      })
      
      moduleServer("leader_proj", function(input, output, session) {
        leaderProjectsServer(input, output, session, pool = pool)
      })
      
      moduleServer("leader_daily", function(input, output, session) {
        leaderDailyReportServer(input, output, session, pool = pool)
      })
      
      moduleServer("leader_weekly", function(input, output, session) {
        leaderWeeklyReportServer(input, output, session, pool = pool)
      })
      
      moduleServer("leader_monthly", function(input, output, session) {
        leaderMonthlyReportServer(input, output, session, pool = pool)
      })
    }
  })
  
}

# Run the app
shinyApp(ui, server)
