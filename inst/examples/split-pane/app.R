library(shiny)
library(shinycapabilities)

grid_data <- data.frame(id=sprintf("row-%03d",1:120),segment=rep(c("Enterprise","Growth","Core"),40),revenue=round(seq(1500,90000,length.out=120),2),margin=round(seq(.12,.41,length.out=120),3),date=as.Date("2026-01-01")+0:119)
schema <- list(
  list(key="method",label="Method",type="choice",choices=c(Regression="regression",Binary="binary"),default="regression",required=TRUE,section="Model"),
  list(key="target",label="Target",type="text",default="revenue",required=TRUE,section="Model"),
  list(key="iterations",label="Iterations",type="integer",default=500L,min=10,max=5000,section="Training"),
  list(key="depth",label="Depth",type="slider",default=8,min=3,max=14,section="Training")
)
card <- function(title,text) div(style="height:100%;padding:14px;background:#fff",h3(title),p(text),tags$div(style="height:600px;background:linear-gradient(#f8fafc,#eef2f6);border:1px solid #dde3ea"))

ui <- fluidPage(tags$head(tags$style(HTML("body{background:#eef2f6}.demo{max-width:1400px;margin:auto;padding:16px}.toolbar{display:flex;gap:8px;margin-bottom:10px}.pane-card{height:100%;padding:12px;background:#fff}.tab-content{padding-top:12px}"))),div(class="demo",
  h2("Accessible Split Pane 1.0"),p("Resize with pointer, touch, or a focused separator and arrow keys. Double-click a separator to reset."),
  tabsetPanel(
    tabPanel("Analytical workspace",div(class="toolbar",actionButton("collapse","Collapse inspector"),actionButton("expand","Expand inspector"),actionButton("reset","Reset layout")),
      split_pane("workspace",data=div(class="pane-card",h3("Analytical data"),data_grid_output("grid",height="100%")),config=div(class="pane-card",parameter_workbench_ui("params",title="Model configuration",height="100%")),sizes=c(68,32),min_sizes=c(35,20),collapsible=c(FALSE,TRUE),height="650px")),
    tabPanel("Three panes",split_pane("three",catalog=card("Catalog","Capability navigation"),canvas=card("Workspace","Primary analytical surface"),inspector=card("Inspector","Contextual details"),sizes=c(20,55,25),min_sizes=c(12,30,12),collapsible=c(TRUE,FALSE,TRUE),height="600px")),
    tabPanel("Vertical",split_pane("vertical",editor=card("Editor","Code or configuration"),output=card("Output","Logs and analytical output"),direction="vertical",sizes=c(45,55),height="620px")),
    tabPanel("Nested",split_pane("outer",workspace=split_pane("inner",top=card("Graph","Interactive graph"),bottom=card("Evidence","Evidence list"),direction="vertical",sizes=c(62,38),height="100%"),detail=card("Detail","Selected object detail"),sizes=c(72,28),min_sizes=c(40,15),height="620px"))
  ),h3("Completed layout event"),verbatimTextOutput("state")))

server <- function(input,output,session){
  output$grid <- render_data_grid(data_grid(grid_data,row_id="id",height="100%"))
  parameter_workbench_server("params",schema=schema,value=list(target="revenue"))
  observeEvent(input$collapse,update_split_pane(session,"workspace",collapse="config"))
  observeEvent(input$expand,update_split_pane(session,"workspace",expand="config"))
  observeEvent(input$reset,update_split_pane(session,"workspace",reset=TRUE))
  output$state <- renderPrint(input$workspace)
}
shinyApp(ui,server)
