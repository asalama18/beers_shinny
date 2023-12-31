
library(tidyverse)
library(dplyr)
library(shiny)
library(ggplot2)
library(ggthemes)

ui <- fluidPage(
  titlePanel("Beers Data Analysis"),
  
  sidebarLayout(
    sidebarPanel(
      fileInput("beers_data", "Choose Beers CSV File", accept = ".csv"),
      fileInput("breweries_data", "Choose Breweries CSV File", accept = ".csv"),
      radioButtons("ibu_plot_type", "Select IBU Plot Type", choices = c("Histogram", "Boxplot")),
      radioButtons("abv_plot_type", "Select ABV Plot Type", choices = c("Histogram", "Boxplot")),
      tags$div(
        tags$line("IBU vs ABV Scatter Plot Configuration:"),
        style = "text-align: left; font-style: bold;"),
      tags$div(
        selectInput("style_filter", "Filter by Style(s)", choices = NULL,
                    selected = NULL, multiple = TRUE),
        selectInput("state_filter", "Filter by States(s)", choices = NULL,
                    selected = NULL, multiple = TRUE),
        checkboxInput("add_regression_line", "Add Regression Line", FALSE)
      )
      
    ),
    
    
    mainPanel(
      plotOutput("ibu_plot"),
      plotOutput("abv_plot"),
      plotOutput("ibu_abv_scatter_plot"),
      plotOutput("max_abv_by_state_plot")
    )
  )
)

server <- function(input, output, session) {
  beers_data <- reactive({
    req(input$beers_data)
    infile <- input$beers_data
    if (is.null(infile)) {
      return(NULL)
    }
    read.csv(infile$datapath)
  })
  
  breweries_data <- reactive({
    req(input$breweries_data)
    breweries_infile <- input$breweries_data
    if (is.null(breweries_infile)) {
      return(NULL)
    }
    read.csv(breweries_infile$datapath)
  })
  
  # Observe the beers file upload and update selectInput choices
  observeEvent(input$beers_data, {
    updateSelectInput(session, "style_filter", choices = unique(beers_data()$Style))
  })
  
  # Observe the beers file upload and update selectInput choices
  observeEvent(input$breweries_data, {
    updateSelectInput(session, "state_filter", choices = unique(breweries_data()$State))
  })
  
  beer_breweries <- reactive({
    #Merge beer data with the breweries data. 
    merged_data <- left_join(beers_data(), breweries_data(), by = c("Brewery_id" = "Brew_ID"))
    # change column names for clarity:
    colnames(merged_data)[colnames(merged_data) == "Name.x"] <- "Beer_Name"
    colnames(merged_data)[colnames(merged_data) == "Name.y"] <- "Brewery_Name"
    return(merged_data)
  })
  
  filtered_data <- reactive({
    if(!is.null(input$style_filter)) {
      filtered_data <- beer_breweries() %>%
        filter(Style %in% input$style_filter)
    } 
    else if(!is.null(input$state_filter)) {
      filtered_data <- beer_breweries() %>%
        filter(State %in% input$state_filter)
    }
    else {
      filtered_data <- beer_breweries()
    }
  })
  
  output$ibu_plot <- renderPlot({
    #create ggplot object for IBU Analysis
    ggp_beers_ibu <- beer_breweries() %>%
      ggplot(mapping = aes(IBU)) +
      ggtitle("IBU Analysis") +
      theme_economist()
    
    # customize ggplot object based on selected plot type
    if (input$ibu_plot_type == "Histogram") {
      beer_breweries() %>%
        ggplot(mapping = aes(IBU)) +
        geom_histogram() +
        xlab("IBU") +
        ylab("Count") +
        ggtitle("IBU Analysis") +
        theme_economist()
    } else {
      beer_breweries() %>%
        ggplot(mapping = aes(IBU)) +
        geom_boxplot() +
        xlab("IBU") +
        ylab("") +
        ggtitle("IBU Analysis") +
        theme_economist()
    }
  })
  
  output$abv_plot <- renderPlot({
    if (input$abv_plot_type == "Histogram") {
      beer_breweries() %>%
        ggplot(mapping = aes(ABV)) +
        geom_histogram() +
        xlab("ABV") +
        ylab("Count") +
        ggtitle("ABV Analysis") +
        theme_economist()
    } else {
      beer_breweries() %>%
        ggplot(mapping = aes(ABV)) +
        geom_boxplot() +
        xlab("ABV") +
        ylab("") +
        ggtitle("ABV Analysis") +
        theme_economist()
    }
  })
  
  output$ibu_abv_scatter_plot <- renderPlot({
    ggp <- filtered_data() %>% ggplot(mapping = aes(IBU, ABV)) + 
      geom_point() +
      ggtitle("IBU vs ABV Analysis") +
      theme_economist()
    
    if (input$add_regression_line) {
      ggp <- ggp + geom_smooth(method = "lm", se = FALSE)
    }
    ggp
  })
  
  output$max_abv_by_state_plot <- renderPlot({
    # calculates and visualizes the maximum ABV & IBU by us state
    # calc max ABV by state
    max_abv_by_state <- beer_breweries() %>% 
      group_by(State) %>%
      summarise(max_ABV = max(ABV, na.rm = TRUE)) %>%
      select(State, max_ABV)
    
    # create a a bar plot for max ABV value in each state
    max_abv_by_state %>% 
      ggplot(mapping = aes(x = reorder(State, +max_ABV))) +
      geom_bar(mapping = aes(y = max_ABV), stat = "identity") + 
      ggtitle("Max ABV by State") +
      xlab("State") +
      ylab("MAX ABV") +
      # geom_text(mapping = aes(reorder(State, +max_ABV), y = max_ABV, 
      #                         label = paste0("             ", round(max_ABV, 4)), angle = 90),
      #           stat = 'identity', size = 4, color = "red") +
      theme_economist()
  })
}
shinyApp(ui, server)

