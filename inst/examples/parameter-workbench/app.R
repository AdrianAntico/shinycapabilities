library(shiny)
library(shinycapabilities)

model_schema <- list(
  list(key="problem_type",label="Problem type",type="choice",choices=c(Regression="regression",Binary="binary"),default="regression",required=TRUE,section="Model"),
  list(key="target",label="Target column",type="text",default="Revenue",required=TRUE,description="Response used for fitting.",section="Model"),
  list(key="trees",label="Trees",type="integer",default=800L,min=10,max=5000,step=10,section="Training"),
  list(key="learning_rate",label="Learning rate",type="numeric",default=.05,min=.001,max=1,step=.001,section="Training"),
  list(key="depth",label="Tree depth",type="slider",default=8,min=3,max=14,section="Training"),
  list(key="class_threshold",label="Classification threshold",type="numeric",default=.5,min=0,max=1,step=.01,section="Training",condition=list(key="problem_type",equals="binary")),
  list(key="compute_shap",label="Compute contribution columns",type="boolean",default=TRUE,section="Outputs"),
  list(key="outputs",label="Scored outputs",type="multi_choice",choices=c(Train="train",Test="test",Full="full"),default=c("test","full"),section="Outputs"),
  list(key="run_date",label="Run date",type="date",default=format(Sys.Date(),"%Y-%m-%d"),section="Governance"),
  list(key="owner",label="Owner",type="text",default="Analytics",read_only=TRUE,section="Governance")
)

large_schema <- c(model_schema, lapply(seq_len(36), function(i) list(
  key=sprintf("parameter_%02d",i),label=sprintf("Optimizer parameter %02d",i),type="numeric",
  default=round(i/10,2),min=0,max=100,step=.1,section=sprintf("Optimizer %d",ceiling(i/9)),
  description="Stress-schema parameter with deterministic bounds."
)))

ui <- fluidPage(tags$head(tags$style(HTML("body{background:#eef2f6}.demo{max-width:1280px;margin:auto;padding:20px}.event{white-space:pre-wrap;background:#fff;border:1px solid #ddd;padding:10px}"))),
  div(class="demo",h2("Typed Parameter Workbench 1.0"),
    p("Model fitting, simulation, and optimizer schemas share the same host-neutral editing contract."),
    radioButtons("schema_mode","Configuration",c("Model fitting"="model","Large optimizer stress"="large"),inline=TRUE),
    actionButton("host_update","Programmatic host update"),
    parameter_workbench_ui("params",title="Analytical configuration",subtitle="Draft locally, validate, then apply.",height="620px"),
    h3("Applied event"),verbatimTextOutput("event",placeholder=TRUE))
)

server <- function(input,output,session){
  schema <- reactive(if(identical(input$schema_mode,"large")) large_schema else model_schema)
  initial <- reactive(list(problem_type="regression",target="Revenue"))
  state <- parameter_workbench_server("params",schema=schema,value=initial,conflict_policy="preserve")
  observeEvent(input$host_update, update_parameter_workbench(session,"params",values=list(problem_type="binary",target="Conversion",trees=1200L),conflict_policy="preserve"))
  output$event <- renderText(jsonlite::toJSON(list(valid=state$valid(),dirty=state$dirty(),conflict=state$conflict(),apply=state$apply_event()),auto_unbox=TRUE,pretty=TRUE,null="null"))
}
shinyApp(ui,server)
