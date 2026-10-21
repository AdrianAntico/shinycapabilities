# Public server-to-browser update witness. No injected client/server state.
library(shiny)
library(shinycapabilities)
ui <- fluidPage(
  selection_input('choice', 'Chart type', groups=list(list(id='kind',label='Kind',
    options=list(list(value='area',label='Area'),list(value='step',label='Step')))),
    selected='area',multiple=FALSE),
  browser_text_field('canvas','Canvas','#ffffff'),
  browser_numeric_field('width','Width',1),
  browser_checkbox('legend','Legend',FALSE),
  actionButton('restore','Restore saved configuration'),
  actionButton('metadata','Update label only'),
  actionButton('clear','Clear values'),
  verbatimTextOutput('received'),verbatimTextOutput('events')
)
server <- function(input,output,session) {
  publications <- reactiveValues(choice=0L,canvas=0L,width=0L,legend=0L,gesture=0L)
  for (key in c('choice','canvas','width','legend')) local({
    k <- key; observeEvent(input[[k]], {publications[[k]] <- isolate(publications[[k]])+1L},ignoreNULL=FALSE,ignoreInit=TRUE)
  })
  observeEvent(input$choice_change,{publications$gesture<-isolate(publications$gesture)+1L},ignoreInit=TRUE)
  observeEvent(input$restore,{
    update_selection_input(session,'choice',selected='step',applied='step')
    update_browser_control(session,'canvas',value='#fff000')
    update_browser_control(session,'width',value=3)
    update_browser_control(session,'legend',value=TRUE)
  })
  observeEvent(input$metadata,{
    update_selection_input(session,'choice',label='Restored chart type')
    update_browser_control(session,'canvas',label='Restored canvas')
  })
  observeEvent(input$clear,{
    update_selection_input(session,'choice',selected=character())
    update_browser_control(session,'canvas',value='')
    update_browser_control(session,'width',value='')
    update_browser_control(session,'legend',value=FALSE)
  })
  output$received<-renderText(jsonlite::toJSON(list(choice=input$choice,canvas=input$canvas,width=input$width,legend=input$legend),auto_unbox=TRUE,null='null'))
  output$events<-renderText(jsonlite::toJSON(reactiveValuesToList(publications),auto_unbox=TRUE))
}
shinyApp(ui,server)
