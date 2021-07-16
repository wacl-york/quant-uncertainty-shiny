library(DBI)
library(RSQLite)
library(shiny)
library(tidyverse)
library(lubridate)
library(shinydashboard)
library(shinycssloaders)
library(ggpubr)
source("reu.R")

DB_FN <- "/mnt/shiny/quant_us/quant.db"

all_devices <- c(
    "AQM388",
    "AQM389",
    "AQM390",
    "AQM391",
    "AQY872",
    "AQY873A",
    "AQY874",
    "AQY875A2",
    "Ari063",
    "Ari078",
    "Ari086",
    "Ari093",
    "Ari096",
    "PA1",
    "PA2",
    "PA3",
    "PA4",
    "PA5",
    "PA6",
    "PA7",
    "PA8",
    "PA9",
    "PA10",
    "Zep188",
    "Zep309",
    "Zep311",
    "Zep344",
    "Zep716"
)


ui <- dashboardPage(

    dashboardHeader(title="QUANT LCS Uncertainty"),
    dashboardSidebar(
            tags$style(".skin-blue .sidebar .shiny-download-link { color: #444; }"),
            radioButtons("species",
                         "Species",
                         choices=c("CO", "NO", "NO2", "O3", "PM1", "PM10", "PM2.5"),
                         selected="NO2"),
            dateRangeInput("daterange",
                           "Time period",
                           startview="year",
                           min="2019-12-10",
                           max=today(),
                           end=today(),
                           start="2019-12-10"),
            radioButtons("location",
                         "Location",
                         choices=c("Manchester", "London", "York"),
                         selected="Manchester"),
            sliderInput("avg",
                         "Minute average",
                         value=60,
                         min=1,
                         max=60),
            checkboxInput("calibrate", "Recalibrate"),
            checkboxGroupInput("devices",
                               "Devices",
                               choices=all_devices),
            actionButton("plot_button",
                         "Plot"),
            downloadButton("download_button", "Download displayed data")
    ),
    dashboardBody(
        fluidRow(
            box(
                title="Time series",
                withSpinner(
                    plotOutput("time_ref")
                ), 
                width=12
            ),
        ),
        fluidRow(
            box(
                title="Scatter",
                withSpinner(
                    plotOutput("scatter")
                ), 
                width=12
            ),
        ),
        fluidRow(
            column(
                radioButtons("error_type",
                             "Error type",
                             choices=c("Absolute (ref - LCS)"="absolute", "REU (GDE)"="REU"),
                             selected="absolute"),
                width=3
            ),
            column(
                numericInput("min_reu",
                             "Minimum REU to display",
                             value=0),
                width=3
            ),
            column(
                numericInput("max_reu",
                             "Maximum REU to display",
                             value=200,
                             min=100),
                width=3
            )
        ),
        fluidRow(
            box(
                title="Error vs time",
                withSpinner(
                    plotOutput("time_plot")
                ),
                width=12
            )
        ),
        fluidRow(
            box(
                title="Error vs concentration",
                withSpinner(
                    plotOutput("conc_plot"),
                ),
                width=12
            ),
        ),
        fluidRow(
            box(
                title="Device deployment history",
                withSpinner(
                    plotOutput("deployment_plot")
                ),
                width=12
            )
        )
    )
)

server <- function(input, output) {
    
    con <- dbConnect(RSQLite::SQLite(), DB_FN)
    lcs <- tbl(con, "lcs")
    ref <- tbl(con, "reference")
    deployments <- tbl(con, "deployments")
    
    selected_data <- eventReactive(input$plot_button, {
        start_time <- as.numeric(as_datetime(as_date(input$daterange[1])))
        end_time <- as.numeric(as_datetime(as_date(input$daterange[2] + 1)))
        avg_str <- sprintf("%d mins", input$avg)
        
        df <- lcs %>%
            filter(variable == !!input$species,
                   device %in% !!input$devices,
                   timestamp >= start_time,
                   timestamp < end_time) %>%
            inner_join(deployments, by="device") %>%
            filter(timestamp >= start, timestamp <= end) %>%
            inner_join(ref, by=c("timestamp", "location", "variable")) %>%
            collect() %>%
            mutate(timestamp = floor_date(as_datetime(timestamp), avg_str)) %>%
            group_by(timestamp, device) %>%
            summarise(lcs = mean(lcs, na.rm=T),
                      reference = mean(reference, na.rm=T)) %>%
            ungroup()
        
        if (input$calibrate) {
            df <- df %>%
                      group_by(device) %>%
                      mutate(lcs = predict(lm(formula=reference ~ lcs), newdata=cur_data())) %>%
                      ungroup()
        }
        
        df
    })
    
    horizontal_line_height <- reactive({
        if (input$error_type == "REU") {
            25
        } else if (input$error_type == "absolute") {
            0
        }
    })
    
    error_data <- reactive({
        if (input$error_type == "REU") {
            err_func <- function(ref, lcs) {
                vals <- reu_gde(x=ref, y=lcs, Approach="GDE")
            }
        } else if (input$error_type == "absolute") {
            err_func <- function(ref, lcs) {
                ref - lcs
            }
        }
        selected_data() %>%
            group_by(device) %>%
            mutate(error = err_func(reference, lcs))
    })

    output$conc_plot <- renderPlot({
        df <- error_data()
        if (input$error_type == "REU") {
            df <- df %>%
                filter(error <= input$max_reu,
                       error >= input$min_reu)
        }
        df %>%
            ggplot(aes(x=reference, y=error)) +
                geom_point(na.rm=T) +
                geom_hline(yintercept = horizontal_line_height(), 
                           colour="green",
                           linetype="dashed") +
                stat_smooth(method="gam", formula=y ~ s(x, bs="cs")) +
                theme_bw() +
                labs(x="Reference (ppb)", y=sprintf("%s", input$error_type)) +
                facet_wrap(~device) 
    })
    
    output$time_plot <- renderPlot({
        if (input$error_type == "REU") {
            summary_text <- error_data() %>%
                group_by(device) %>%
                summarise(lab = sprintf("Mean REU: %.2f%%", mean(error, na.rm=T)),
                          x=min(timestamp) + 0.80 * (max(timestamp) - min(timestamp)), y=Inf)
            
        } else if (input$error_type == "absolute") {
            summary_text <- error_data() %>%
                group_by(device) %>%
                summarise(lab = sprintf("RMSE: %.2f", sqrt(mean(error**2, na.rm=T))),
                          x=min(timestamp) + 0.80 * (max(timestamp) - min(timestamp)), y=Inf)
        }
        
        
        df <- error_data()
        if (input$error_type == "REU") {
            df <- df %>%
                filter(error <= input$max_reu,
                       error >= input$min_reu)
        }
        
        p <- df %>%
            ggplot(aes(x=timestamp, y=error)) +
                geom_line(na.rm=T) +
                geom_hline(yintercept = horizontal_line_height(), 
                           colour="green",
                           linetype="dashed") +
                geom_text(aes(label=lab, x=x, y=y), data=summary_text, vjust=1) +
                theme_bw() +
                labs(x="", y=sprintf("%s", input$error_type)) +
                facet_wrap(~device)
        
        
        p
        
    })
    
    output$time_ref <- renderPlot({
        selected_data() %>%
            ggplot(aes(x=timestamp)) +
                geom_line(aes(y=lcs, colour="LCS"), na.rm=T) +
                geom_line(aes(y=reference, colour="Reference"), na.rm=T) +
                theme_bw() +
                theme(legend.position="bottom") +
                labs(x="", y=sprintf("%s", input$species)) +
                facet_wrap(~device) +
                scale_colour_manual("", values=c("Black", "Red"))
    })
    
    output$scatter <- renderPlot({
        selected_data() %>%
            ggplot(aes(x=reference, y=lcs)) +
                geom_point(na.rm=T) +
                theme_bw() +
                labs(x="Reference", y="LCS") +
                geom_smooth(method="lm") +
                stat_regline_equation(
                    aes(label =  paste(..eq.label.., ..rr.label.., sep = "~~~~")),
                ) + 
                facet_wrap(~device) 
    })
    
    
    output$deployment_plot <- renderPlot({
        df <- deployments %>%
            collect() %>%
            mutate(start = as_datetime(start),
                   end = as_datetime(end),
                   range = as.integer(difftime(end, start, units="days")),
                   midpoint = as_date(start) + floor((range)/2),
                   device=as.factor(device))
        device_ids <- rev(levels(df$device))
        df %>%
            ggplot(aes(x=midpoint, y=as.numeric(device), fill=location, width=range)) +
                geom_tile(na.rm=T) +
                theme_bw() +
                labs(x="", y="") +
                scale_x_date(date_breaks="4 months",
                             date_labels = "%b %y") +
                theme(panel.grid.major.x = element_blank(),
                      panel.grid.minor.x = element_blank(),
                      panel.grid.minor.y = element_blank()) +
                scale_y_continuous(breaks = 1:length(device_ids),
                                   labels = device_ids,
                                   sec.axis = dup_axis()) +
                scale_fill_discrete("") +
                theme(legend.position="bottom")
    })
    
    output$download_button <- downloadHandler(
        filename = function() {
            paste0("quant_extract_", Sys.Date(), ".csv")
        },
        content = function(file) {
            df <- selected_data() %>%
                    group_by(device) %>%
                    mutate(reu = reu_gde(x=reference, y=lcs, Approach="GDE"),
                           error = reference - lcs)
            write_csv(df, file)
        }
    )
    
}

shinyApp(ui = ui, server = server)