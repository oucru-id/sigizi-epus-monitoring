library(shiny)

ui <- fluidPage(
  titlePanel("SIGIZI–EPUS Monitoring"),
  tags$p(
    "Initial project scaffold for ANC, INC, and PNC monitoring. "
    "The BigQuery data contract has not yet been connected."
  )
)

server <- function(input, output, session) {
  # Server modules will be added after the monitoring views are defined.
}

shinyApp(ui, server)

